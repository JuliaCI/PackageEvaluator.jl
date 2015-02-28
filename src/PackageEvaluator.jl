#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################

module PackageEvaluator

include("package.jl")
include("constants.jl")
include("metatools.jl")
include("util.jl")

import JSON

# eval_pkg
# Performs all tests on a single package.
export eval_pkg
function eval_pkg(  pkg::String;
                    # Whether to look for & load PKGEVAL_$pkg_add.log
                    loadpkgadd=false,
                    # Whether to use a timeout on the tests
                    usetimeout=true,
                    # Path to the Julia package directory to use.
                    # Defaults to Julia's default, which is assumed to be
                    # initialized already.
                    juliapkg =nothing,
                    # Whether or not to write the output as a JSON
                    asjson   =true,
                    # What folder to write the JSON to
                    jsonpath ="./"
                    )
    # Initialize feature dictionary
    features = Dict{Symbol,Any}()

    # Expand out path
    juliapkg = (juliapkg == nothing) ? Pkg.dir() : abspath(juliapkg)

    # Load pacakge add log, if asked
    features[:ADD_LOG] = "No package add log available"
    if loadpkgadd
        print_with_color(:yellow, "PKGEVAL: Loading package add log\n")
        try
            features[:ADD_LOG] = readall("PKGEVAL_$(pkg)_add.log")
        catch e
            print_with_color(:yellow, "PKGEVAL: Loading add log failed!\n")
        end
    end

    # Find where the package is and go there
    jl_cmd_arg  = (juliapkg != nothing) ? "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\";" : ""
    jl_cmd_arg *= "println(Pkg.dir()); println(Pkg.dir(\"$pkg\")); print(Pkg.installed(\"$pkg\"))"
    pkg_info = readall(`julia -e $jl_cmd_arg`)
    pkg_root = split(pkg_info,"\n")[1]
    pkg_path = split(pkg_info,"\n")[2]
    features[:VERSION] = split(pkg_info,"\n")[3]
    print_with_color(:yellow, "PKGEVAL: Package path is $pkg_path\n")

    # Get package information
    print_with_color(:yellow, "PKGEVAL: Collecting general information\n")
    getInfo(features, pkg, pkg_path)  # General info (e.g. url, commit)
    checkLicense(features, pkg_path)  # Determine license

    # Actually run the tests
    print_with_color(:yellow, "PKGEVAL: Attempting to run tests\n")
    checkTesting(features, pkg_path, pkg, usetimeout, juliapkg)

    # Produce a JSON if requested
    asjson && featuresToJSON(pkg, features, jsonpath)

    return features
end

end