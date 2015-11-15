#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build_pulse.jl
# Builds the Package Ecosystem Pulse page.
#-----------------------------------------------------------------------

print_with_color(:magenta, "Building pulse page...\n")

import JSON, Mustache

include("shared.jl")
const RELEASE = "0.3"
const NIGHTLY = "0.4"

# Load test history
date_str     = ARGS[1]
star_db_file = ARGS[2]
hist_db_file = ARGS[3]
output_path  = ARGS[4]

# Load package listing, turn into a more useful dictionary
pkgs = JSON.parsefile("final.json")
pkgdict = Dict(RELEASE=>Dict(), NIGHTLY=>Dict())
for pkg in pkgs
    pkgdict[pkg["jlver"]][pkg["name"]] = pkg
end

# Load package history
hist_db, pkgnames, hist_dates = load_hist_db(hist_db_file)

# Load template, initialize template dictionary
template = readall("html/pulse_temp.html")
temp_data = Dict{Any,Any}("UPDATEDATE" => string(dbdate_to_date(date_str)))

#-----------------------------------------------------------------------
# CHANGES
#-----------------------------------------------------------------------

print_with_color(:magenta, "  Package version changes... ")

# Build a list of changes in the last 7 days:
# * new packages
# * version bumps
changes = Any[]
for pkgname in pkgnames
    hist_key = (pkgname, NIGHTLY)
    # If no history for this package, just punt
    hist_key ∉ keys(hist_db) && continue
    hist = hist_db[hist_key]
    # Get version now
    cur_ver  = hist[1,2]
    cur_date = dbdate_to_date(hist[1,1])
    # Get rid of entries that possibly only briefly existed in METADATA
    abs(convert(Int, cur_date - dbdate_to_date(date_str))) >= 2 && continue
    # Try to get version a week ago
    pre_ver = cur_ver
    new_this_week = true
    for i in 2:size(hist, 1)
        pre_date = dbdate_to_date(hist[i,1])
        if convert(Int, cur_date - pre_date) >= 7
            pre_ver = hist[i,2]
            new_this_week = false  # Becaue it existed then
            break
        end
    end
    # Is it new package?
    if new_this_week
        push!(changes, (:new, pkgname, cur_ver, cur_ver))
    elseif pre_ver != cur_ver
        push!(changes, (:upd, pkgname, pre_ver, cur_ver))
    end
end
sort!(changes)

# Convert changes into template dictionaries
disp_changes = Any[]
temp_data["NUMNEWPKG"] = 0
temp_data["NUMUPDPKG"] = 0
for c in changes
    change_type, pkgname, pre_ver, cur_ver = c
    pd = pkgdict[NIGHTLY][pkgname]
    temp_change = Dict()
    temp_change["icon"] = (change_type == :new) ? "star" : "arrow-up"
    temp_change["name"] = pkgname
    temp_change["post"] = cur_ver
    temp_change["pre"]  = (change_type == :new) ? "" : pre_ver*" →"
    if change_type == :new
        temp_data["NUMNEWPKG"] += 1
    elseif change_type == :upd
        pre_ver == cur_ver && continue
        temp_data["NUMUPDPKG"] += 1
    end
    temp_change["url"] = pd["url"]
    temp_change["sha"] = pd["gitsha"]
    push!(disp_changes, temp_change)
end
temp_data["CHANGESLEFT"]  = disp_changes[1:div(length(disp_changes),2)+1]
temp_data["CHANGESRIGHT"] = disp_changes[div(length(disp_changes),2)+2:end]

println("new: ", temp_data["NUMNEWPKG"], ", updated: ", temp_data["NUMUPDPKG"])

#-----------------------------------------------------------------------
# STARS
#-----------------------------------------------------------------------

print_with_color(:magenta, "  Star changes...\n")

star_hist, star_dates = load_star_db(star_db_file)
star_changes = Any[]
for pkgname in keys(star_hist)
    # Get info now
    cur_info = star_hist[pkgname][1]
    cur_date = dbdate_to_date(cur_info[1])
    cur_star = cur_info[2]
    # Try to get version a week ago (or best effort)
    pre_star = 0
    for i in 2:length(star_hist[pkgname])
        pre_info = star_hist[pkgname][i]
        pre_date = dbdate_to_date(pre_info[1])
        pre_star = pre_info[2]
        convert(Int, cur_date - pre_date) >= 14 && break
    end
    push!(star_changes, (pkgname, cur_star, pre_star))
end
sort!(star_changes)

# Get top ten by count
star_top_alltime = sort(star_changes, by=f->f[2], rev=true)
temp_data["TOPSTARALLTIME"] = Any[]
for i in 1:10
    pkgname, cur_star, pre_star = star_top_alltime[i]
    push!(temp_data["TOPSTARALLTIME"], Dict(
                "url"       => pkgdict[NIGHTLY][pkgname]["url"],
                "name"      => pkgname,
                "count"     => cur_star,
                "change"    => cur_star - pre_star ))
end

# Get top ten by change
star_top_change = sort(star_changes, by=f->(f[2]-f[3]), rev=true)
temp_data["TOPSTARCHANGE"] = Any[]
for i in 1:10
    pkgname, cur_star, pre_star = star_top_change[i]
    push!(temp_data["TOPSTARCHANGE"], Dict(
                "url"       => pkgdict[NIGHTLY][pkgname]["url"],
                "name"      => pkgname,
                "count"     => cur_star,
                "change"    => cur_star - pre_star ))
end

#-----------------------------------------------------------------------
# STATUS TOTALS
#-----------------------------------------------------------------------

print_with_color(:magenta, "  Status totals...\n")

totals = Dict{Any,Any}(RELEASE => Dict(), NIGHTLY => Dict())
for JULIA_VERSION in [RELEASE, NIGHTLY]
    for pkgname in pkgnames
        hist_key = (pkgname, JULIA_VERSION)
        # If no history for this package, just punt
        hist_key ∉ keys(hist_db) && continue
        hist = hist_db[hist_key]
        # Get version now
        cur_date = hist[1,1]
        cur_ver  = hist[1,2]
        cur_stat = hist[1,3]
        # Right version?
        if cur_date == date_str
            totals[JULIA_VERSION][cur_stat] =
                get(totals[JULIA_VERSION], cur_stat, 0) + 1
            totals[JULIA_VERSION]["total"] =
                get(totals[JULIA_VERSION], "total", 0) + 1
        end
    end
end

function rel_num(count, total)
    @sprintf("%d (%.0f%%)", count, count/total*100)
end

RELEASE_total = totals[RELEASE]["total"]
temp_data["RELEASEPASS"]    = rel_num(totals[RELEASE]["tests_pass"],    RELEASE_total)
temp_data["RELEASEFAIL"]    = rel_num(totals[RELEASE]["tests_fail"],    RELEASE_total)
temp_data["RELEASENOTEST"]  = rel_num(totals[RELEASE]["no_tests"],      RELEASE_total)
temp_data["RELEASEUNTEST"]  = rel_num(totals[RELEASE]["not_possible"],  RELEASE_total)
temp_data["RELEASETOTAL"]   = string(RELEASE_total)

NIGHTLY_total = totals[NIGHTLY]["total"]
temp_data["NIGHTLYPASS"]    = rel_num(totals[NIGHTLY]["tests_pass"],    NIGHTLY_total)
temp_data["NIGHTLYFAIL"]    = rel_num(totals[NIGHTLY]["tests_fail"],    NIGHTLY_total)
temp_data["NIGHTLYNOTEST"]  = rel_num(totals[NIGHTLY]["no_tests"],      NIGHTLY_total)
temp_data["NIGHTLYUNTEST"]  = rel_num(totals[NIGHTLY]["not_possible"],  NIGHTLY_total)
temp_data["NIGHTLYTOTAL"]   = string(NIGHTLY_total)

#-----------------------------------------------------------------------
# STATUS CHANGES
#-----------------------------------------------------------------------

print_with_color(:magenta, "  Status changes...\n")

changes = Dict(RELEASE => Dict(), NIGHTLY => Dict())
for JULIA_VERSION in [RELEASE, NIGHTLY]
    for date in hist_dates[1:5]
        changes[JULIA_VERSION][date] = []
    end
    for pkgname in pkgnames
        hist_key = (pkgname, JULIA_VERSION)
        # If no history for this package, just punt
        hist_key ∉ keys(hist_db) && continue
        hist = hist_db[hist_key]
        # How many days of history?
        hist_days = min(size(hist,1), 5)
        # Look for changes
        for days_back in 1:hist_days
            cur_date   = hist[days_back, 1]
            cur_status = hist[days_back, 3]
            pre_status = "new"
            if days_back + 1 <= size(hist,1)
                pre_status = hist[days_back+1, 3]
            end
            if cur_date ∉ keys(changes[JULIA_VERSION])
                break
            end
            if cur_status != pre_status
                push!(changes[JULIA_VERSION][cur_date], Dict(
                    "name"  =>  pkgname,
                    "prev"  =>  pre_status,
                    "cur"   =>  cur_status,
                    "url"   =>  pkgdict[JULIA_VERSION][pkgname]["url"],
                    "purl"  =>  "../logs/$(pkgname)_$(JULIA_VERSION).log"
                    ))
            end
        end
    end
    for date in hist_dates[1:5]
        sort!(changes[JULIA_VERSION][date], by=d->d["name"])
    end
end

temp_data["RELEASECHANGES"] = [Dict(
    "TESTDATE"      => hist_dates[i],
    "STATUSCHANGE"  => changes[RELEASE][hist_dates[i]]) for i in 1:5]
temp_data["NIGHTLYCHANGES"] = [Dict(
    "TESTDATE"      => hist_dates[i],
    "STATUSCHANGE"  => changes[NIGHTLY][hist_dates[i]]) for i in 1:5]

#-----------------------------------------------------------------------
# RENDER
#-----------------------------------------------------------------------

print_with_color(:magenta, "  Rendering...\n")

open(joinpath(output_path, "pulse.html"), "w") do fp
    print(fp, Mustache.render(template, temp_data))
end
