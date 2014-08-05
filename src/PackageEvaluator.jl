#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################

module PackageEvaluator

include("package.jl")
include("constants.jl")
include("metatools.jl")
include("util.jl")

# evalPkg
# Performs all tests on a single package. Return dict. of test results.
export evalPkg
function evalPkg(pkg::String; addremove=true, usetimeout=true)
    # Initialize
    features = Dict{Symbol,Any}()

    # Add package, if needed, and log adding
    features[:ADD_LOG] = "Did not add package first"
    if addremove
        jl_cmd_arg = "Pkg.add(\"$pkg\")"
        features[:ADD_LOG], ok = 
            run_cap_all(`julia -e $jl_cmd_arg`, "$(pkg)_add.log")
    end

    # Get package URL and version from METADATA
    url_path = joinpath(Pkg.dir(),"METADATA",pkg, "url")
    url      = chomp(readall(url_path))
    url      = (url[1:3] == "git")   ? url[7:(end-4)] :
               (url[1:5] == "https") ? url[9:(end-4)] : ""
    features[:URL] = string("http://", url)
    features[:VERSION] = string(Pkg.installed(pkg))

    # Analyze package itself
    pkg_path = Pkg.dir(pkg)
    cd(pkg_path)
    getInfo(features, pkg_path)             # General info (e.g. commit)
    checkLicense(features, pkg_path)        # Determine license
    checkTesting(features, pkg_path, pkg, usetimeout)
                                            # Actually run package tests
    
    addremove && Pkg.rm(pkg)  # Remove Pkg if necessary

    return features
end


# featuresToJSON
# Takes test results and formats them as a JSON string
export featuresToJSON
function featuresToJSON(pkg_name, features)
    keyToJSON(key, value, last=false) = "  \"$key\": \"" *
                                        value * 
                                        "\"$(!last?",":"")\n"
    json_str = "{\n"
    json_str *= keyToJSON("jlver",    string(VERSION.major,".",VERSION.minor))
    json_str *= keyToJSON("name",     pkg_name)
    json_str *= keyToJSON("url",      features[:URL])
    json_str *= keyToJSON("version",  features[:VERSION])
    json_str *= keyToJSON("gitsha",   chomp(features[:GITSHA]))
    json_str *= keyToJSON("gitdate",  chomp(features[:GITDATE]))
    json_str *= keyToJSON("license",  features[:LICENSE])
    json_str *= keyToJSON("licfile",  features[:LICENSE_FILE])
    json_str *= keyToJSON("status",   features[:TEST_STATUS])
    json_str *= keyToJSON("log",      escape_string(build_log(pkg_name,
                                                                features[:ADD_LOG],
                                                                features[:TEST_USING_LOG],
                                                                features[:TEST_FULL_LOG])))
    json_str *= keyToJSON("possible", features[:TEST_POSSIBLE] ? "true" : "false", true)

    json_str *= "}"
    return json_str
end

# testAllPkgs
# Run evalPkg on all packages, and write a JSON for results of each
export testAllPkgs
function testAllPkgs(;limit=Inf,usetimeout=true)
    # Walk through each package in METADATA (assume updated)
    cur_dir = pwd()
    available_pkg = Pkg.available()
    done = 0
    for pkg_name in available_pkg
        println("##### Current package: $pkg_name")

        features = nothing
        try
            deps = get(PackageEvaluator.EXCEPTIONS, pkg_name, {})
            map(Pkg.add, deps)
            features = evalPkg(pkg_name, addremove=true,
                                         usetimeout=usetimeout)
            map(Pkg.rm,  deps)
        catch
            println("      !!!!!! evalPkg failed")
            continue
        end

        cd(cur_dir)
        json_fp = open(joinpath(cur_dir,"$(pkg_name).json"),"w")
        write(json_fp, featuresToJSON(pkg_name, features))
        close(json_fp)

        # Limit number of packages to test
        done += 1 
        done >= limit && break
    end
end

#######################################################################
end #module
