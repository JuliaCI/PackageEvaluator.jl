#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/update_db.jl
# Take the results and repository information, and update the test and
# start history databases.
#-----------------------------------------------------------------------

print_with_color(:magenta, "Update databases...\n")

using JSON, GitHub, JLD

all_pkgs = JSON.parsefile("all.json")

if length(ARGS) == 3
    # Date and release/nightly
    if length(ARGS[1]) != 8
        error("First argument must be date in YYYYMMDD format")
    end
    datestr = ARGS[1]
    star_db_path = ARGS[2]
    hist_db_path = ARGS[3]
else
    error("""
        Expected 3 arguments
        * YYYYMMDD as first argument
        * Star DB path, and History DB path""")
end

# Load repository info
pkg_repo_infos = load("pkg_repo_infos.jld", "pkg_repo_infos")

# Update star history
print_with_color(:yellow, "Updating star history database... ")
star_fp = open(star_db_path, "a")
total_stars = 0
for (pkg_name, repo_info) in pkg_repo_infos
    if repo_info == nothing
        println(star_fp, datestr, ", ",
                lpad(pkg_name,30," "), ",",
                lpad("0",5," ") )
        continue
    end
    println(star_fp, datestr, ", ",
            lpad(pkg_name,30," "), ",",
            lpad(string(repo_info.stargazers_count),5," ") )
    total_stars += repo_info.stargazers_count
end
close(star_fp)
println("Done. Total stars: ", total_stars)

# Update test history
print_with_color(:yellow, "Updating test history database... ")
hist_fp = open(hist_db_path, "a")  # APPEND
for pkg in all_pkgs
    println(hist_fp, datestr, ", ",
            pkg["jlver"], ",",
            lpad(pkg["name"],   30," "), ",",
            lpad(pkg["version"],10," "), ", ",
            pkg["status"])
end
close(hist_fp)
println("Done. Total entries added: ", length(all_pkgs))
