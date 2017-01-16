#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/JuliaCI/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build_site_data.jl
# Take the results and repository information, and produce a single
# JSON with all information required to construct the website. At the
# same time, produce all badges and log files - avoid creating the
# badge if there is no change.
#-----------------------------------------------------------------------

print_with_color(:magenta, "Merging repo info, creating badges and logs...\n")

using JSON, GitHub, JLD
import MetadataTools
import Requests
include("shared.jl")

if length(ARGS) != 3
    error("Expected 3 arguments: log folder, badge folder, history path")
end
log_path = ARGS[1]
badge_path = ARGS[2]
hist_path = ARGS[3]

# Load results and repository info
all_pkgs = JSON.parsefile("all.json")
pkg_repo_infos = load("pkg_repo_infos.jld", "pkg_repo_infos")

# Load history
hist_db, _, _ = load_hist_db(hist_path)

# MetadataTools can determine the highest Julia version a package can
# be installed on (ignoring the fact that dependencies may themselves
# have limits). The version v0.0.0 is set if no such limit exists.
metadata_pkgs = MetadataTools.get_all_pkg()
deprecated = Dict()
for pkg_meta in values(metadata_pkgs)
    ul = MetadataTools.get_upper_limit(pkg_meta)
    deprecated[pkg_meta.name] = (ul != v"0.0.0")
end

# Using MetadataTools, we can also get the number of dependencies for,
# and number of packages that depend on, each package
import MetadataTools: make_dep_graph, get_pkg_dep_graph
pgfwd = make_dep_graph(metadata_pkgs)
pgrev = make_dep_graph(metadata_pkgs, reverse=true)
fwddep_counts = Dict()
revdep_counts = Dict()
for pkg_meta in values(metadata_pkgs)
    fwddep_counts[pkg_meta.name] = size(get_pkg_dep_graph(pkg_meta, pgfwd)) - 1
    revdep_counts[pkg_meta.name] = size(get_pkg_dep_graph(pkg_meta, pgrev)) - 1
end

# Mapping of test statuses to badge text and color
const badge_status = Dict(
    "tests_pass"    => "Tests%20Pass",
    "tests_fail"    => "Tests%20Fail",
    "no_tests"      => "No%20Tests",
    "not_possible"  => "Not%20Tested"
    )
const badge_color = Dict(
    "tests_pass"    => "brightgreen",
    "tests_fail"    => "red",
    "no_tests"      => "blue",
    "not_possible"  => "lightgrey"
    )

# Process all packages for all tested Julia versions
for pkg in all_pkgs
    println(pkg["name"], ", ", pkg["jlver"])

    # Make log file
    log_file = joinpath(log_path, string(pkg["name"],"_",pkg["jlver"],".log"))
    open(log_file,"w") do logfp
        if length(pkg["log"]) <= 40_000_000
            println(logfp, pkg["log"])
        else
            println(logfp, pkg["log"][1:20_000_000])
            println(logfp)
            println(logfp, "... log truncated to make github less angry ...")
            println(logfp)
            println(logfp, pkg["log"][end-20_000_000:end])
        end
    end

    # Add description and stars
    if pkg["name"] in keys(pkg_repo_infos) &&
                pkg_repo_infos[pkg["name"]] != nothing
        pkg["githubdesc"]  = pkg_repo_infos[pkg["name"]]["description"]
        pkg["githubstars"] = pkg_repo_infos[pkg["name"]]["stargazers_count"]
    else
        warn(pkg["name"], " has no repository information!")
        pkg["githubdesc"]  = "No description available."
        pkg["githubstars"] = 0
    end

    # Add deprecation notice
    if pkg["name"] in keys(deprecated)
        pkg["deprecated"] = deprecated[pkg["name"]]
    else
        warn(pkg["name"], " has no deprecation information! Update METADATA?")
        pkg["deprecated"] = false
    end

    # Add dependency info
    if pkg["name"] in keys(fwddep_counts)
        pkg["fwddep"] = fwddep_counts[pkg["name"]]
        pkg["revdep"] = revdep_counts[pkg["name"]]
    else
        warn(pkg["name"], " has no dependency count information! Update METADATA?")
        pkg["fwddep"] = 0
        pkg["revdep"] = 0
    end

    # Make badge using shields.io, if needed
    # Identify last status and version for this package
    key = (pkg["name"], pkg["jlver"])
    if key in keys(hist_db)
        h = hist_db[key][1,:]
        prev_ver, prev_status = h[2], h[3]

        if prev_ver == pkg["version"] &&
            prev_status == pkg["status"]
            # No change in the badge, so don't bother
            print_with_color(:blue, "  No change in version and status, skipping\n")
            continue
        end
    end

    req_url = string("http://img.shields.io/badge/Julia%20v", pkg["jlver"],
                        "-v", pkg["version"], "%20",
                        badge_status[pkg["status"]], "-",
                        badge_color[pkg["status"]], ".svg")
    r = Requests.get(req_url)
    if Requests.statuscode(r) != 200
        print_with_color(:red, "  No badge generated (HTTP status != 200)\n")
        print_with_color(:red, string("  ", Requests.statuscode(r), "  ", Requests.text(r), "\n"))
    else
        badge_file = joinpath(badge_path,
                        string(pkg["name"],"_",pkg["jlver"],".svg"))
        open(badge_file,"w") do badge_fp
            print(badge_fp, Requests.text(r))
        end
        print_with_color(:green, "  Success\n")
    end
end

# Save enhanced JSON
print("Saving enhanced JSON... ")
open("final.json","w") do fp
    print(fp, JSON.json(all_pkgs))
end
println("Done.")
