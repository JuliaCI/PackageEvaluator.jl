using Compat
using Compat.Test

# Check src/constants.jl loads
src_dir = joinpath(splitdir(@__FILE__)[1], "..", "src")
include(joinpath(src_dir, "constants.jl"))

# Check preptest.jl works
try
    run(`$(ENV["_"]) $(joinpath(src_dir, "preptest.jl")) Arduino`)
    error("preptest didn't exit correctly")
catch err
    @test contains(err.msg, "255")
end
run(`$(ENV["_"]) $(joinpath(src_dir, "preptest.jl")) JSON`)
@test isfile("JSON.sh")
rm(joinpath(pwd(),"JSON.sh"))

# Check prepjson works
open("PKGEVAL_JSON_add.log","w") do nothing end
open("PKGEVAL_JSON_test.log","w") do nothing end
run(`$(ENV["_"]) $(joinpath(src_dir, "prepjson.jl")) JSON 0 $(pwd())`)
rm("PKGEVAL_JSON_add.log")
rm("PKGEVAL_JSON_test.log")
@test isfile("JSON.json")

# Check joinjson works
run(`$(ENV["_"]) $(joinpath(src_dir, "joinjson.jl")) $(pwd()) test`)
@test isfile("test.json")
rm("JSON.json")
rm("test.json")
