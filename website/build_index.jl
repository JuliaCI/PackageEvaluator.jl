#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/JuliaCI/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build_index.jl
# The main page is built by combining a header, a footer, and then
# repeating a middle chunk for every package. The templates are stored
# in the website/html/ subfolder, and are populated using Mustache.
# At the same time, create subpages for each package that has all the
# extra-for-experts stuff like histories, badges, and logs.
#-----------------------------------------------------------------------

print_with_color(:magenta, "Building index page and detail pages...\n")

using Compat, JSON, Humanize, Mustache, TimeZones
include("shared.jl")

# Load test history
if length(ARGS) != 2
    error("Expected 2 arguments, the path of the test history database and the output directory.")
end
hist_db_file = ARGS[1]
hist_db, _, _ = load_hist_db(hist_db_file)

# Load all package info
all_pkgs = JSON.parsefile("final.json")
pkgs_by_name = Dict()
for pkg in all_pkgs
    pkg_name = pkg["name"]
    if pkg_name in keys(pkgs_by_name)
        push!(pkgs_by_name[pkg_name], pkg)
    else
        pkgs_by_name[pkg_name] = [pkg]
    end
end
pkg_names = sort(collect(keys(pkgs_by_name)))

# Load logo
jllogo_svg = read("html/jllogo.svg", String)

# Load stylesheet
pkg_css = read("html/pkg.css", String)

# Load and render header
index_head = Mustache.render(read("html/indexhead.html", String),
    Dict("JLLOGO"      => jllogo_svg,
         "PKGCSS"      => pkg_css,
         "LASTUPDATED" => string(Dates.today()),  # YYYY-MM-DD
         "PKGCOUNT"    => string(length(pkg_names))) )

# Load footer (no templates used)
index_foot = read("html/indexfoot.html", String)

# Load the template for a package
index_pkg = read("html/indexpkg.html", String)

# Load the package detail template
pkg_detail = read("html/pkgdetail.html", String)

# Helper function to produce history listings for each package
function hist_table(hist_db, pkg_name, jl_ver)
    output_strs = AbstractString[]
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

parsedate(s::AbstractString) =
    TimeZones.utc(parse(ZonedDateTime, s, dateformat"yyyy-mm-dd HH:MM:SS zzzzz"))

listings = String[]

# For each package in the data set
for pkg_name in pkg_names
    # Sort by ascending Julia version
    sort!(pkgs_by_name[pkg_name], by=pkg->pkg["jlver"])
    # Construct a dictionary to populate the Mustache template
    temp_data = Dict()
    # First populate data that is either invariant between versions,
    # or when ambiguous, the most recent information available
    pkg = pkgs_by_name[pkg_name][end]
    temp_data["NAME"]        = pkg["name"]
    temp_data["LOWER_NAME"]  = lowercase(pkg["name"])
    owner = split(pkg["url"],"/")[end-1]
    temp_data["OWNER"]       = owner
    temp_data["LOWER_OWNER"] = lowercase(owner)
    temp_data["STARS"]       = pkg["githubstars"]
    temp_data["LICENSE"]     = pkg["license"]
    temp_data["LICENSE_URL"] = string(pkg["url"], "/blob/",
                                    pkg["gitsha"], "/", pkg["licfile"])
    temp_data["URL"]         = pkg["url"]
    temp_data["DESC"]        = (pkg["githubdesc"] == "nothing" ? "" : pkg["githubdesc"])
    temp_data["DEPSTR"]      = (pkg["deprecated"] ? """/ <span class=\"using_fail\"
                                                    title=\"Package is no longer supported and
                                                    may not install on the next Julia release\">
                                                    deprecated</span>""" : "")
    temp_data["FWDDEP"]      = pkg["fwddep"]
    temp_data["REVDEP"]      = pkg["revdep"]
    # For per-package detail page
    temp_data["PKG_LINK"]    = string("http://pkg.julialang.org/detail/", pkg["name"])

    # Now add per-version information
    temp_data["PERVERSION"] = Dict[]
    for pkg in pkgs_by_name[pkg_name]
        ver_data = Dict(
            "JLVER"         => pkg["jlver"],
            "STATUS"        => pkg["status"],
            "SHA"           => pkg["gitsha"],
            "VER"           => pkg["version"],
            "DTSTR"         => Humanize.timedelta(Dates.now() - parsedate(pkg["gitdate"])),
            "HUMAN_STATUS"  => HUMANSTATUS[pkg["status"]],
            # For per-package detail page
            "SVG_URL"      => string("../badges/",
                                        pkg["name"], "_", pkg["jlver"], ".svg"),
            "SVG_LINK"      => string("http://pkg.julialang.org/badges/",
                                        pkg["name"], "_", pkg["jlver"], ".svg"),
            "HIST_DATA"     => hist_table(hist_db, pkg["name"], pkg["jlver"]),
            "LOG_LINK"      => string("../logs/", pkg["name"],
                                        "_", pkg["jlver"], ".log"))
        push!(temp_data["PERVERSION"], ver_data)
    end

    push!(listings, Mustache.render(index_pkg, temp_data))

    temp_data["JLLOGO"] = jllogo_svg
    temp_data["PKGCSS"] = pkg_css
    open(joinpath(ARGS[2],"detail","$(pkg_name).html"),"w") do fp
        println(fp, Mustache.render(pkg_detail, temp_data))
    end
end

# Output finished product
open(joinpath(ARGS[2],"index.html"),"w") do fp
    println(fp, index_head)
    println(fp, join(listings, "\n"))
    println(fp, index_foot)
end
