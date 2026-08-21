#!/bin/bash
set -euo pipefail

# ============================================================
# Prepare transient AWI-CM-1-1-MR SSS forcing for FESOM2
#
# Workflow:
#   native AWI-CM sos
#      -> merge/select years
#      -> remap to PHC-style 1 degree grid
#      -> rename sos to SALT
#      -> split into yearly files
#
# Historical: 1958-2014
# SSP585:     2015-2100
# ============================================================

# ---------- USER PATHS ----------
BASE="/albedo/work/projects/p_trr181/ebagaeva/work/FESOM_Xinyue/SSS_AWICM"
HIST="${BASE}/historical"
FUT="${BASE}/ssp585"

# Use the PHC-style grid description shipped with this repository.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRID="${SCRIPT_DIR}/phc2_grid.txt"

# ============================================================
# 1. HISTORICAL: 1958-2014
# ============================================================

cd "${HIST}"

echo "=== Historical 1958-2014 ==="

cdo -O selyear,1958/2014 -mergetime \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_195101-196012.nc \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_196101-197012.nc \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_197101-198012.nc \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_198101-199012.nc \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_199101-200012.nc \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_200101-201012.nc \
    sos_Omon_AWI-CM-1-1-MR_historical_r1i1p1f1_gn_201101-201412.nc \
    sos_AWICM_historical_1958-2014_native.nc

echo -n "Historical native timesteps (expected 684): "
cdo -s ntime sos_AWICM_historical_1958-2014_native.nc

cdo -O remapdis,"${GRID}" \
    sos_AWICM_historical_1958-2014_native.nc \
    sos_AWICM_historical_1958-2014_phcgrid.nc

cdo -O chname,sos,SALT \
    sos_AWICM_historical_1958-2014_phcgrid.nc \
    SALT_AWICM_historical_1958-2014.nc

rm -f SALT_AWICM.[12][0-9][0-9][0-9].nc

cdo splityear \
    SALT_AWICM_historical_1958-2014.nc \
    SALT_AWICM.

# ============================================================
# 2. SSP585: 2015-2100
# ============================================================

cd "${FUT}"

echo "=== SSP585 2015-2100 ==="

cdo -O mergetime \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_201501-202012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_202101-203012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_203101-204012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_204101-205012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_205101-206012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_206101-207012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_207101-208012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_208101-209012.nc \
    sos_Omon_AWI-CM-1-1-MR_ssp585_r1i1p1f1_gn_209101-210012.nc \
    sos_AWICM_ssp585_2015-2100_native.nc

echo -n "SSP585 native timesteps (expected 1032): "
cdo -s ntime sos_AWICM_ssp585_2015-2100_native.nc

cdo -O remapdis,"${GRID}" \
    sos_AWICM_ssp585_2015-2100_native.nc \
    sos_AWICM_ssp585_2015-2100_phcgrid.nc

cdo -O chname,sos,SALT \
    sos_AWICM_ssp585_2015-2100_phcgrid.nc \
    SALT_AWICM_ssp585_2015-2100.nc

rm -f SALT_AWICM.2[0-9][0-9][0-9].nc

cdo splityear \
    SALT_AWICM_ssp585_2015-2100.nc \
    SALT_AWICM.

# ============================================================
# 3. BASIC VALIDATION
# ============================================================

echo "=== Validation ==="

echo -n "Historical count (expected 57): "
find "${HIST}" -maxdepth 1 -name 'SALT_AWICM.[12][0-9][0-9][0-9].nc' \
    | awk -F. '$2 >= 1958 && $2 <= 2014' \
    | wc -l

echo -n "SSP585 count (expected 86): "
find "${FUT}" -maxdepth 1 -name 'SALT_AWICM.2[0-9][0-9][0-9].nc' \
    | wc -l

echo "Preparation complete."
