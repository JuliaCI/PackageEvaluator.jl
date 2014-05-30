using PackageEvaluator

function testAll(limit)
    # Walk through each package in METADATA (assume updated)
    available_pkg = Pkg.available()
    done = 0
    for pkg_name in available_pkg
        println("##### Current package: $pkg_name")
      
        # Run PackageEvaluator
        features = nothing
        try
            deps = get(PackageEvaluator.EXCEPTIONS, pkg_name, {})
            map(Pkg.add, deps)
            features = evalPkg(pkg_name, true)  # addremove
            map(Pkg.rm,  deps)
        catch
            println("      !!!!!! evalPkg failed")
            continue
        end

        json_str = featuresToJSON(pkg_name, features)
        json_fp = open(joinpath(cur_dir,"$(pkg_name).json"),"w")
        write(json_fp, json_str)
        close(json_fp)

        # Limit number of packages to test
        done += 1 
        done >= limit && break
    end
end

length(ARGS) != 1 && error("Expected argument: num_to_test")
testAll(int(ARGS[1]) == -1 ? Inf : int(ARGS[1]))
