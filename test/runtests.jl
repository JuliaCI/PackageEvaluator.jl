using PackageEvaluator
using Base.Test

HttpCommon_results = evalPkg("HttpCommon",usetimeout=false)

@test HttpCommon_results[:LICENSE] == "MIT"
@test HttpCommon_results[:TEST_EXIST]

testAllPkgs(limit=5,usetimeout=false)