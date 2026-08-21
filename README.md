# FESOM2 transient AWI-CM SSS restoring

Development of transient monthly sea-surface salinity restoring for FESOM2 using AWI-CM-1-1-MR CMIP6 output.

Main additions:
- new `sss_data_source = 'AWICM_SSS'`
- year-dependent monthly SSS input: `SALT_AWICM.YEAR.nc`
- preprocessing from native AWI-CM grid to the regular 1° PHC-style grid
- Arctic restoring reduction using `fac = 0.33`, following Qiang Wang's implementation
- standard FESOM global-mean restoring correction retained

The repository contains:
- `src/` — modified FESOM2 source files
- `scripts/` — preprocessing workflow for AWI-CM SSS
- `docs/` — development notes and implementation details

The actual CMIP6/NetCDF forcing files are not stored in this repository.
