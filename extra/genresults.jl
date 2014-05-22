using PackageEvaluator


function testAll(limit, writeJSON, writeHTML)
    
    cur_dir = pwd()  # Can get lost a bit running tests

    if writeHTML
        summary = open(joinpath(cur_dir,"index.html"),"w")

        # Setup the index file by copying in a header from a file in 
        # the extra/ folder
        preindex_path = joinpath(Pkg.dir("PackageEvaluator"),"extra","preindex.inc")
        preindex = open(preindex_path,"r")
        write(summary, readall(preindex))
        close(preindex)
    end

    # Walk through each package in METADATA (assume updated)
    available_pkg = Pkg.available()
    done = 0
    for pkg_name in available_pkg
        println("##### Current package: $pkg_name")

        # Check to see if already have JSON
        if writeJSON && !writeHTML && isfile(joinpath(Pkg.dir("PackageEvaluator"),"extra","$(pkg_name).json"))
            println("      ?????? Already have JSON, skipping")
            continue
        end

        
        # Run PackageEvaluator
        features = nothing
        try
            # Run any preprocessing
            exceptions_before(pkg_name)
            # Add and remove it
            features = evalPkg(pkg_name, true)
            # Run any postprocessing
            exceptions_after(pkg_name)
        catch
            # Couldn't process package, about!
            println("      !!!!!! evalPkg failed")
            continue
        end

        

        # Write a row
        if writeHTML
            write(summary, "<tr>\n")
            # Package
            write(summary, "  <td>$pkg_name</td>\n")
            # Repo
            write(summary, "  <td><a href=\"$(features[:URL])\">$(pkg_name).jl</a></td>\n")
            # License
            if features[:LICENSE] == "Unknown"
                write(summary, "  <td class=\"red\">?</td>")
            else
                write(summary, "  <td class=\"grn\">$(features[:LICENSE])</td>\n")
            end
            
            # Testing
            write(summary, "  <td class=\"$(features[:TEST_STATUS]) thk\"></td>")
            details = getDetailsString(pkg_name, features)
            write(summary, "  <td>$details</td>\n")
            
            # Pkg req
            if features[:REQUIRE_VERSION]
                write(summary, "  <td class=\"grn thk\"></td>")
            else
                write(summary, "  <td class=\"thk\"></td>")
            end
            # META req
            if features[:REQUIRES_OK]
                write(summary, "  <td class=\"grn\"></td>")
            else
                write(summary, "  <td></td>")
            end
            # TravisCI
            if features[:TEST_TRAVIS]
                write(summary, "  <td class=\"grn\"></td>")
            else
                write(summary, "  <td></td>")
            end

            write(summary, "</tr>\n")
        end

        # WriteJSON
        if writeJSON
            json_str = featuresToJSON(pkg_name, features)
            json_fp = open(joinpath(cur_dir,"$(pkg_name).json"),"w")
            write(json_fp, json_str)
            close(json_fp)
        end

        # Limit number of packages to test
        done = done + 1
        if done >= limit
            break
        end
    end

    if writeHTML
        write(summary, "</table></div></div></body></html>")
        close(summary)
    end
end


###############################################################################
# EXCEPTIONS FOR PACKAGE SETUP AND TEARDOWN
# Some packages require packages for testing, but don't explicitly depend on
# them. Please submit PRs if this applies to your package
###############################################################################
const EXCEPTIONS = ["CRC" => ["Zlib"],
                    "DecisionTree" => ["RDatasets"],
                    "ExpressionUtils" => ["FactCheck"],
                    "Gadfly" => ["RDatasets", "Cairo"],
                    "GLM" => ["DataFrames"],
                    "HTTPClient" => ["JSON"],
                    "ImageView" => ["TestImages"],
                    "JuMP" => ["Cbc","Clp","GLPKMathProgInterface"],
                    "MarketTechnicals" => ["Datetime", "FactCheck","MarketData"],
                    "MarketData" => ["FactCheck"],
                    "MathProgBase" => ["Cbc", "Clp"],
                    "PLX" => ["BinDeps", "MAT"],
                    "Synchrony" => ["CrossDecomposition"],
                    "TimeModels" => ["FactCheck", "MarketData"],
                    "TimeSeries" => ["Datetime", "FactCheck", "MarketData"]
                    ]

# exceptions_before
# Any "special" testing commands to be done
function exceptions_before(pkg_name)
    if pkg_name in keys(EXCEPTIONS)
        for pkg_dep in EXCEPTIONS[pkg_name]
            Pkg.add(pkg_dep)
        end
    end
end

# exceptions_after
# Any cleanup for packages that had exceptions
function exceptions_after(pkg_name)
    if pkg_name in keys(EXCEPTIONS)
        for pkg_dep in EXCEPTIONS[pkg_name]
            Pkg.rm(pkg_dep)
        end
    end
end


###############################################################################
# Parse arguments and run
###############################################################################
if length(ARGS) != 2
    error("Expected two arguments: num_to_test and output_types")
end
# First argument: number of tests to run, -1 is all of them
num_to_test = int(ARGS[1])
if num_to_test == -1
    num_to_test = Inf
end
# Second argument: output types: J, H, or JH
writeJSON = contains(ARGS[2], "J")
writeHTML = contains(ARGS[2], "H")

testAll(num_to_test, writeJSON, writeHTML)
