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

    # Expand out path
    juliapkg = (juliapkg == nothing) ? Pkg.dir() : abspath(juliapkg)

    # Add package, if needed, and log adding it
    if addremove
        print_with_color(:yellow, "PKGEVAL: Installing $pkg\n")
        add_path = "PKGEVAL_$(pkg)_add.jl"
        fp = open(add_path,"w")
        if juliapkg != nothing
            println(fp, "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\"")
            println(fp, "Pkg.init()")
        end
        println(fp, "Pkg.add(\"$pkg\")")
        features[:ADD_LOG], ok =
            run_cap_all(`$juliapath $add_path`, "PKGEVAL_$(pkg)_add.log")
        if !ok
            print_with_color(:yellow, "PKGEVAL: Installation failed!\n")
            # Was it a build problem, or was it a can't-install-at-all problem?
            if contains(features[:ADD_LOG], "can't be installed because it has no versions")
                print_with_color(:yellow, "PKGEVAL: $pkg can't be installed, aborting\n")
                return features
            end
        end
    else
        print_with_color(:yellow, "PKGEVAL: Skipping installation\n")
        features[:ADD_LOG] = "Did not add package first"
    end

    # Find where the package is and go there
    jl_cmd_arg  = (juliapkg != nothing) ? "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\"; Pkg.init();" : ""
    jl_cmd_arg *= "println(Pkg.dir()); println(Pkg.dir(\"$pkg\")); print(Pkg.installed(\"$pkg\"))"
    pkg_info = readall(`$juliapath -e $jl_cmd_arg`)
    pkg_root = split(pkg_info,"\n")[1]
    pkg_path = split(pkg_info,"\n")[2]
    features[:VERSION] = split(pkg_info,"\n")[3]
    print_with_color(:yellow, "PKGEVAL: Package path is $pkg_path\n")

    # Get package information
    print_with_color(:yellow, "PKGEVAL: Collecting general information\n")
    getInfo(features, pkg, pkg_path)        # General info (e.g. url, commit)
    checkLicense(features, pkg_path)        # Determine license

    # Actually run the tests
    print_with_color(:yellow, "PKGEVAL: Attempting to run tests\n")
    checkTesting(features, pkg_path, pkg, usetimeout, juliapath, juliapkg)

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
    asjson && featuresToJSON(pkg, features, jsonpath)

    return features
end

export eval_pkgs
function eval_pkgs(;# DEBUG: limit number of packages evaluated
                    limit=-1,
                    # All other options passed through to eval_pkg
                    options...)
    print_with_color(:magenta, "PKGEVAL: eval_pkgs(subset=$subset)\n")
    # Walk through each package in METADATA
    pkg_names = Pkg.available()
    limit != -1 && (pkg_names = pkg_names[1:limit])
    for pkg_name in pkg_names
        print_with_color(:magenta, "PKGEVAL: Attempting to evaluate $pkg_name\n")
        try
            eval_pkg(pkg_name; options...)
        catch e
            print_with_color(:magenta, "PKGEVAL: Uncaught exception with eval_pkg($pkg_name)\n")
            dump(e)
        end
    end
end


end
