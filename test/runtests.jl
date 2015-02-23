using PackageEvaluator
using Base.Test

HttpCommon_results = evalPkg("HttpCommon",usetimeout=false)
@test HttpCommon_results[:LICENSE] == "MIT"
@test HttpCommon_results[:TEST_EXIST]

ArgParse_results = evalPkg("HttpCommon",usetimeout=false)
@test ArgParse_results[:TEST_STATUS] == "full_pass"
@test ArgParse_results[:LICENSE_FILE] == "LICENSE.txt"

ASCIIPlots_results = evalPkg("ASCIIPlots",usetimeout=false)
@test ASCIIPlots_results[:TEST_STATUS] == "full_pass(
