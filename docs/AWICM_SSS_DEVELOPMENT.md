# Transient AWI-CM SSS restoring in FESOM2

**Date:** 20 Aug 2026  
**Model:** FESOM2.7.0  
**Forcing:** AWI-CM-1-1-MR CMIP6, historical + SSP585

## Goal

Add a transient monthly sea-surface salinity restoring target based on AWI-CM-1-1-MR output, while keeping the standard FESOM restoring formulation and global-mean correction. Reduce restoring strength in the Arctic following Qiang's regional factor.

## What was changed

### 1. Prepared AWI-CM SSS forcing

- Used monthly CMIP6 `sos` from AWI-CM-1-1-MR `r1i1p1f1`.
- Historical: 1958–2014.
- SSP585: 2015–2100.
- Remapped the native unstructured AWI-CM grid to the regular 1° PHC-style grid with CDO `remapdis`.
- Renamed `sos` to `SALT`.
- Split into yearly 12-month files:

```text
SALT_AWICM.1958.nc
...
SALT_AWICM.2100.nc
```

### 2. Added a new SSS source

In `gen_surface_forcing.F90`, added:

```fortran
sss_data_source = 'AWICM_SSS'
```

The model constructs a year-dependent filename:

```fortran
filename = trim(make_full_path(nm_sss_data_file)) // cyearnew // '.nc'
```

and reads the selected month with the existing regular-grid reader:

```fortran
call read_other_NetCDF(filename, 'SALT', i, Ssurf, .true., .true., partit, mesh)
```

Typical namelist setting:

```fortran
sss_data_source  = 'AWICM_SSS'
nm_sss_data_file = '/path/to/SALT_AWICM.'
```

### 3. Kept the standard restoring physics

The transient target is still used in the standard restoring expression:

```fortran
relax_salt(n) = surf_relax_S * &
                (Ssurf(n) - salt(ulevels_nod2d(n),n))
```

The existing global area-mean correction remains unchanged, so restoring does not introduce a net global salt source/sink.

### 4. Added reduced Arctic restoring

Following Qiang's approach, the restoring is weakened in the Arctic:

```fortran
fac = 1.0_WP

if (sss_data_source == 'AWICM_SSS') then
    y = geo_coord_nod2D(2,n) / rad
    x = geo_coord_nod2D(1,n) / rad

    if (y > 77.0_WP .or. &
        (y > 66.0_WP .and. (x > 15.0_WP .or. x < -50.0_WP))) then
        fac = 0.33_WP
    end if
end if

relax_salt(n) = fac * surf_relax_S * &
                (Ssurf(n) - salt(ulevels_nod2d(n),n))
```

The factor is applied **only** to `AWICM_SSS`; `CORE1/CORE2` restoring is unchanged.

To make the namelist source visible in `ice_oce_coupling.F90`:

```fortran
! gen_surface_forcing.F90
public :: sss_data_source
```

```fortran
! ice_oce_coupling.F90
use g_sbf, only: sss_data_source
```

and the local variables were extended to include:

```fortran
real(kind=WP) :: rsss, net, fac, x, y
```

## Validation

- FESOM compiles successfully.
- A short runtime test confirmed that `AWICM_SSS` is recognized and the year-dependent SSS file is read correctly.
- Historical forcing contains 57 yearly files (1958–2014), 12 months each.
- SSP585 forcing contains 86 yearly files (2015–2100), 12 months each.

## Remaining decision

Finalize the baseline `surf_relax_S` restoring strength for the production run.
