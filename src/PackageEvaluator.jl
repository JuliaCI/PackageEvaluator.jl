module PackageEvaluator

export evaluatePackage

function evaluatePackage(repo_url)
    features = Dict{ASCIIString,Any}()

    # Extract repository name
    pkg_name = split(repo_url, "/")[end][1:(end-4)]
    # Clone to local directory
    println("Cloning package '$pkg_name'...")
    #run(`git clone $repo_url`)
    println("Done!")

    # Check REQUIRE file
    checkREQUIRE(features, pkg_name)

    println(features)

    # Clean up
    #run(`rm -rf $pkg_name`)
end

function checkREQUIRE(features, pkg_name)
    REQUIRE_path = joinpath(pkg_name,"REQUIRE")
    if isfile(REQUIRE_path)
        # Exists
        features["REQUIRE exists"] = true
        # Does it specifiy a Julia dependency?
        grep_result = readall(REQUIRE_path)
        features["REQUIRE Julia version"] = ismatch(r"julia", grep_result)
    else
        # Does not exist
        features["REQUIRE exists"] = false
    end
end

end
