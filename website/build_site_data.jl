#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build_site_data.jl
# Take the results and repository information, and produce a single
# JSON with all information required to construct the website. At the
# same time, produce all badges and log files.
#-----------------------------------------------------------------------

using JSON, GitHub, JLD
import MetadataTools
import Requests

if length(ARGS) != 2
    error("Expected 2 arguments: log folder and badge folder")
end
log_path = ARGS[1]
badge_path = ARGS[2]

# Load results and repository info
all_pkgs = JSON.parsefile("all.json")
pkg_repo_infos = load("pkg_repo_infos.jld", "pkg_repo_infos")

# MetadataTools can determine the highest Julia version a package can
# be installed on (ignoring the fact that dependencies may themselves
# have limits). The version v0.0.0 is set if no such limit exists.
metadata_pkgs = MetadataTools.get_all_pkg()
deprecated = Dict()
for pkg_meta in values(metadata_pkgs)
    ul = MetadataTools.get_upper_limit(pkg_meta)
    deprecated[pkg_meta.name] = (ul != v"0.0.0")
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
    print(pkg["name"], ", ", pkg["jlver"])

    # Make log file
    log_file = joinpath(log_path, string(pkg["name"],"_",pkg["jlver"],".log"))
    open(log_file,"w") do logfp
        println(logfp, pkg["log"])
    end

    # Add description and stars
    if pkg["name"] in keys(pkg_repo_infos)
        pkg["githubdesc"]  = pkg_repo_infos[pkg["name"]].description
        pkg["githubstars"] = pkg_repo_infos[pkg["name"]].stargazers_count
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

    # Make badge using shields.io
    req_url = string("https://img.shields.io/badge/Julia%20v", pkg["jlver"],
                        "-v", pkg["version"], "%20",
                        badge_status[pkg["status"]], "-",
                        badge_color[pkg["status"]], ".svg")
    r = Requests.get(req_url)
    if Requests.statuscode(r) != 200
        warn("No badge generated for ", pkg["name"], ", ", pkg["jlver"])
        @show Requests.statuscode(r)
        @show Requests.text(r)
    else
        badge_file = joinpath(badge_path,
                        string(pkg["name"],"_",pkg["jlver"],".svg"))
        open(badge_file,"w") do badge_fp
            print(badge_fp, Requests.text(r))
        end
    end
end

# Save enhanced JSON
print("Saving enchanced JSON... ")
open("final.json","w") do fp
    print(fp, JSON.json(all_pkgs))
end
println("Done.")