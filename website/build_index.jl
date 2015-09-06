#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build_index.jl
# The main page is built by combining a header, a footer, and then
# repeating a middle chunk for every package. The templates are stored
# in the website/html/ subfolder, and are populated using Mustache.
#-----------------------------------------------------------------------

import JSON, Humanize, Mustache
include("shared.jl")

# Load test history
if length(ARGS) != 2
    error("Expected 2 arguments, the path of the test history database and the output filename.")
end
hist_db_file = ARGS[1]
hist_db, _, _ = load_hist_db(hist_db_file)

# Load all package info
all_pkgs = JSON.parsefile("final.json")

# Load and render header
index_head = Mustache.render(readall("html/indexhead.html"),
    Dict("LASTUPDATED" => string(Dates.today()),  # YYYY-MM-DD
         "PKGCOUNT"    => string(div(length(all_pkgs),2))) )  # Estimate

# Load footer (no templates used)
index_foot = readall("html/indexfoot.html")

# Load the template for a package
index_pkg = readall("html/indexpkg.html")

# Helper function to produce history listings for each package
function hist_table(hist_db, pkg_name, jl_ver)
    output_strs = String[]
    hist = hist_db[(pkg_name, jl_ver)]
    pos = size(hist,1)
    cur_start_date = date_nice(hist[pos,1])
    cur_end_date   = date_nice(hist[pos,1])
    cur_version    = hist[pos,2]
    cur_status     = HUMANSTATUS[hist[pos,3]]
    while true
        pos -= 1
        if pos == 0
            # End of history
            push!(output_strs, cur_start_date * " to " * cur_end_date *
                    ", v" * cur_version * ", " * cur_status * "\n")
            break
        end
        pos_date    = date_nice(hist[pos,1])
        pos_version = hist[pos,2]
        pos_status  = HUMANSTATUS[hist[pos,3]]
        if pos_version != cur_version || pos_status != cur_status
            # Change in state because new version of package or status change
            push!(output_strs, cur_start_date * " to " * cur_end_date *
                    ", v" * cur_version * ", " * cur_status * "\n")
            cur_start_date  = pos_date
            cur_end_date    = pos_date
            cur_version     = pos_version
            cur_status      = pos_status
        else
            # No changes to worry about it
            cur_end_date = pos_date
        end
    end

    return join(reverse(output_strs))
end



listings = UTF8String[]

for pkg in all_pkgs
    println(pkg["name"], ", ", pkg["jlver"])

    owner = split(pkg["url"],"/")[end-1]
    push!(listings, Mustache.render(index_pkg, Dict(
        "LOWER_NAME"    => lowercase(pkg["name"]),
        "LOWER_OWNER"   => lowercase(owner),
        "JLVER"         => pkg["jlver"],
        "STATUS"        => pkg["status"],
        "LICENSE"       => pkg["license"],
        "URL"           => pkg["url"],
        "NAME"          => pkg["name"],
        "DESC"          => (pkg["githubdesc"] == "nothing" ? "" : pkg["githubdesc"]),
        "SHA"           => pkg["gitsha"],
        # Top block
        "VER"           => pkg["version"],
        "DTSTR"         => Humanize.timedelta(Dates.now() - 
                                DateTime(pkg["gitdate"],"y-m-d H:M:S")),
        "DEPSTR"        => (pkg["deprecated"] ? """ <span class=\"using_fail\"
                                                    title=\"Package is no longer supported and
                                                    may not install on the next Julia release\">
                                                    deprecated</span> / """ : ""),
        "LICENSE_URL"   => string(pkg["url"], "/blob/",
                                    pkg["gitsha"], "/", pkg["licfile"]),
        "OWNER"         => owner,
        "STARS"         => pkg["githubstars"],
        # Middle block
        "HUMAN_STATUS"  => HUMANSTATUS[pkg["status"]],
        # Bottom block
        "MINOR"         => pkg["jlver"][end:end],
        "PKG_LINK"      => string("http://pkg.julialang.org/?pkg=",
                                    pkg["name"], "&ver=", pkg["jlver"]),
        "SVG_LINK"      => string("http://pkg.julialang.org/badges/",
                                    pkg["name"], "_", pkg["jlver"], ".svg"),
        "HIST_DATA"     => hist_table(hist_db, pkg["name"], pkg["jlver"])
        )))
end

# Output finished product
open(ARGS[2],"w") do fp
    println(fp, index_head)
    println(fp, join(listings, "\n"))
    println(fp, index_foot)
end