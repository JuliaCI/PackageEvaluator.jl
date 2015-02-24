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

# evalPkg
# Performs all tests on a single package.
export evalPkg
function evalPkg(   pkg::String;
                    # Whether the package should be added be trying to test it
                    addremove=true,
                    # Whether to use a timeout on the test
                    usetimeout=true,
                    # Path to the Julia executable to use
                    juliapath="julia",
                    # Path to the Julia package directory to use
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

    # Add package, if needed, and log adding it
    if addremove
        print_with_color(:yellow, "PKGEVAL: Installing $pkg\n")
        if juliapkg == nothing
            jl_cmd_arg = "Pkg.add(\"$pkg\")"
        else
            jl_cmd_arg = "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\";" *
                         "Pkg.init(); Pkg.add(\"$pkg\")"
        end
        features[:ADD_LOG], ok =
            run_cap_all(`$juliapath -e $jl_cmd_arg`, "$(pkg)_add.log")
        !ok && print_with_color(:yellow, "PKGEVAL: Installation failed!\n")
    else
        print_with_color(:yellow, "PKGEVAL: Skipping installation\n")
        features[:ADD_LOG] = "Did not add package first"
    end

    # Find where the package is and go there
    jl_cmd_arg  = (juliapkg != nothing) ? "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\"; Pkg.init();" : ""
    jl_cmd_arg *= "println(Pkg.dir()); print(Pkg.dir(\"$pkg\"))"
    pkg_info = readall(`$juliapath -e $jl_cmd_arg`)
    pkg_root = split(pkg_info,"\n")[1]
    pkg_path = split(pkg_info,"\n")[2]
    print_with_color(:yellow, "PKGEVAL: Package path is $pkg_path\n")

    # Get package information
    print_with_color(:yellow, "PKGEVAL: Collecting general information\n")
    getInfo(features, pkg, pkg_path)        # General info (e.g. url, commit)
    checkLicense(features, pkg_path)        # Determine license

    # Actually run the tests
    print_with_color(:yellow, "PKGEVAL: Attempting to run tests\n")
    checkTesting(features, pkg_path, pkg, usetimeout, juliapath, juliapkg, pkg_root)

    # Remove Pkg if requested
    if addremove
        print_with_color(:yellow, "PKGEVAL: Uninstalling $pkg\n")
        if juliapkg == nothing
            jl_cmd_arg = "Pkg.rm(\"$pkg\")"
        else
            jl_cmd_arg = "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\";" *
                         "Pkg.rm(\"$pkg\")"
        end
        run(`$juliapath -e $jl_cmd_arg`)
    end

    # Produce a JSON if requested
    if asjson
        featuresToJSON(pkg, features, jsonpath)
    end

    return features
end


# featuresToJSON
# Takes test results and formats them as a JSON string
function featuresToJSON(pkg_name, features, jsonpath)
    output_dict = {
        "jlver"             => string(VERSION.major,".",VERSION.minor),
        "name"              => pkg_name,
        "url"               => features[:URL],
        "version"           => features[:VERSION],
        "gitsha"            => chomp(features[:GITSHA]),
        "gitdate"           => chomp(features[:GITDATE]),
        "license"           => features[:LICENSE],
        "licfile"           => features[:LICENSE_FILE],
        "status"            => features[:TEST_STATUS],
        "log"               => build_log(pkg_name,  features[:ADD_LOG],
                                                    features[:TEST_USING_LOG],
                                                    features[:TEST_FULL_LOG]),
        "possible"          => features[:TEST_POSSIBLE] ? "true" : "false"
    }
    j_path = joinpath(jsonpath,pkg_name*".json")
    print_with_color(:yellow, "PKGEVAL: Creating JSON file $j_path\n")
    fp = open(j_path,"w")
    JSON.print(fp, output_dict)
    close(fp)
end


end #module
