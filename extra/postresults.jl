#############################################################################
# PackageEvaluator
# A package that evaluates (all) other packages, then generates various
# outputs that feed into various websites.
# https://github.com/IainNZ/PackageEvaluator.jl
#############################################################################
# postresults.jl
# 1. Take the log file that captures all stdout and stderr from running
#    genresults.jl and extract the per-package logs.
# 2. Stick those in a dictionary, trimming off the "removing" section and
#    truncating if too long (e.g. due to binary build logs)
# 3. Open & parse each output JSON file, jam the test log in
# 4. Add the JSON string to a concatenated list of JSONs in concat.json
# 5. POST the JSON to status.julialang.org
#
# Disable POSTing by adding the argument nopost, e.g. 
#    julia postresults.jl nopost
#
#############################################################################

# The data structure we extract from the log file for every package
type PackageData
    name
    main_ver
    deps
    lines
    test_log
end
PackageData(name) = PackageData(name, "", Any[], Any[], "")
function add_line!(pd::PackageData, line)
    contains(line, "INFO: Removing") && return
    push!(pd.lines, line)
    if contains(line, "INFO: Installing")
        pkg_name, pkg_ver = split(line[18:end]," ")
        if pkg_name == pd.name
            pd.main_ver = pkg_ver
        else
            push!(pd.deps, (pkg_name, pkg_ver))
        end
    end
end
function compress_lines!(pd::PackageData)
    if length(pd.lines) > 25
        pd.test_log = join(vcat(pd.lines[1:10], pd.lines[end-10:end]),"\n")
    else
        pd.test_log = join(pd.lines,"\n")
    end
end
function print_deps(pd::PackageData, all_pkg, depth=0, done_already=nothing)
    # MESSED UP BECAUSE IT DOESN'T REFLECT JUST DIRECT DEPENDENCIES

    # Don't repeat packages in the tree
    if done_already == nothing
        done_already = Dict()
        for dep in pd.deps
            done_already[dep[1]] = false
        end
    end
    done_already[pd.name] = true

    indent = ""
    for i = 1:depth
        indent *= "  "
    end
    println(indent * pd.name)
    #readline()
    for dep in pd.deps
        if done_already[dep[1]]
            # Hack because some packages have optional includes
            #continue
        end
        print_deps(all_pkg[dep[1]], all_pkg, depth+1, done_already)
    end
end
    

#############################################################################

# Assume we running in a nuked package folder
Pkg.add("Requests")
using Requests
using JSON

# Check whether we want to POST or not
do_post = !(length(ARGS) >= 1 && ARGS[1] == "nopost")
println("do_post ", do_post)

#############################################################################
## Log file processing
#############################################################################
# Find the most recent log file in the folder
all_files = readdir()
log_files = Any[]
for file in all_files
    contains(file, "pkgeval_") && push!(log_files, file)
end
sort!(log_files)

# Open it up and stick it into a structure for each package
log_data = split(readall(log_files[end]),"\n")
pkg_log = Dict()
cur_pkg_name = ""
for line in log_data
    if contains(line, "##### Current package")
        cur_pkg_name = strip(split(line, ":")[2])
        pkg_log[cur_pkg_name] = PackageData(cur_pkg_name)
    else
        add_line!(pkg_log[cur_pkg_name], line)
    end
end

# Compress all the lines down into one string - trimming if too long
for key in keys(pkg_log)
    compress_lines!(pkg_log[key])
end

#############################################################################
## Dependency tree
#############################################################################
#print_deps(pkg_log["DataFrames"], pkg_log)
#print_deps(pkg_log["Gadfly"], pkg_log)


#############################################################################
## Concatenate and post JSONs
#############################################################################
cat_fp = open("concat.json","w")
json_head = ["Content-Type" => "application/json"]

first = true
for file in all_files
    if !ismatch(r"json", file) || contains(file, "concat.json")
        continue
    end

    # Load the JSON in and parse it so we can insert the test log
    json_str = readall(file)
    json_dict = JSON.parse(json_str)
    if json_dict["name"] in keys(pkg_log)
        json_dict["testlog"] = pkg_log[json_dict["name"]].test_log
    else
        json_dict["testlog"] = "No log! Please file issue."
    end

    # Append the current JSON
    !first && print(cat_fp, ",")
    first = false
    println(cat_fp, JSON.json(json_dict))

    # Only post if the not disabled
    !do_post && continue 
    println(file)
    try
        response = post(URI("http://status.julialang.org/put/package"), JSON.json(json_dict), json_head)
        println(response)
    catch
        println("Failed to post $file, removing test log")
        println(json_dict["testlog"])
        json_dict["testlog"] = "Log error! Please file issue."
	println(JSON.json(json_dict))
        try
            response = post(URI("http://status.julialang.org/put/package"), JSON.json(json_dict), json_head)
            println(response)
        end
    end
end

#############################################################################
## Tidy up
#############################################################################
close(cat_fp)
Pkg.rm("Requests")
