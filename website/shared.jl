#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/shared.jl
# Functionality required across scripts
#-----------------------------------------------------------------------

# Human-readable versions of the test codes
const HUMANSTATUS = Dict(
        "tests_pass"    => "Tests pass.",
        "tests_fail"    => "Tests fail.",
        "no_tests"      => "No tests detected.",
        "not_possible"  => "Package was untestable.",
        "new_pkg"       => "N/A - new package.",
        "total"         => "",
        # OLD STATUS CODES
        "full_pass"     => "Test exist, they pass.",
        "full_fail"     => "Test exist, they fail, but package loads.",
        "using_pass"    => "No tests, but package loads.",
        "using_fail"    => "No tests, package doesn't load.")

# Take the YYYYMMDD date format and turn it in YYYY-MM-DD
date_nice(orig::String) = string(orig[1:4],"-",orig[5:6],"-",orig[7:8])
date_nice(orig::Int) = date_nice(string(orig))

# Takes a database YYYYMMDD date and turns it into a Date instance
dbdate_to_date(dbdate) =
    Date(parse(Int,dbdate[1:4]),
         parse(Int,dbdate[5:6]),
         parse(Int,dbdate[7:8]))

# Load the history database CSV, turn it into a dictionary keyed on
# the package name and the Julia version
# Returns 
#  - Dictionary where keys are (name,jlver) and values are matrices with
#    columns [dates pkgver status], sorted so most recent is at top.
#  - Set of all package names seen in the database
#  - Vector of all dates seen in the database
function load_hist_db(hist_db_file)
    all_hist = readcsv(hist_db_file, String)
    # Remove all the whitespace from all fields
    map!(strip, all_hist)
    # Form the dictionaries and sets
    hist_db  = Dict()
    pkg_set  = Set()
    date_set = Set()
    for row in 1:size(all_hist,1)
        DATE    = all_hist[row,1]
        JLVER   = all_hist[row,2]
        NAME    = all_hist[row,3]
        PKGVER  = all_hist[row,4]
        STATUS  = all_hist[row,5]
        key     = (NAME, JLVER)
        value   = [DATE PKGVER STATUS]  # Row of matrix

        hist_db[key] = key in keys(hist_db) ? 
                        vcat(hist_db[key], value) :
                        value
        push!(pkg_set,  NAME)
        push!(date_set, DATE)
    end
    # Sort histroy by descending dates (most recent first)
    for key in keys(hist_db)
        val = hist_db[key]
        hist_db[key] = val[sortperm(val[:,1], rev=true), :]
    end
    return hist_db, pkg_set, sort(collect(date_set),rev=true)
end

# load_star_db
# Given the package listing star database filename, 
# produces:
#  - an dictionary (key: package name) of arrays 
#    of stars by date.
#  - an array of all dates seen in the file.
function load_star_db(hist_file)
    # Load CSV
    all_hist = readcsv(hist_file, String)
    # Remove all the whitespace
    map!(strip, all_hist)
    # Store results in a dictionary keyed on on package
    # names, with values being an array of (date,stars)
    hist = Dict()
    # Also track a set of all dates ever seen
    dates = Set()
    # Iterate through all rows of the history
    for row in 1:size(all_hist,1)
        date    = all_hist[row,1]  # Format: YYYYMMDD
        pkgname = all_hist[row,2]
        stars   = parse(Int,all_hist[row,3])
        # Create the result
        result  = (date,stars)
        # Check if a dictionary has an entry for this
        # package yet
        if pkgname in keys(hist)
            push!(hist[pkgname], result)
        else
            hist[pkgname] = [result]
        end
        # Update the sets
        push!(dates, date)
    end
    # For convenience, we sort entries for every package
    # in descending order of dates
    for pkgname in keys(hist)
        sort!(hist[pkgname], rev=true)
    end
    # Return arrays instead of sets
    return hist, sort(collect(dates),rev=true)  # from present to past
end