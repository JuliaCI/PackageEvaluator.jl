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
        # OLD STATUS CODES
        "full_pass"     => "Test exist, they pass.",
        "full_fail"     => "Test exist, they fail, but package loads.",
        "using_pass"    => "No tests, but package loads.",
        "using_fail"    => "No tests, package doesn't load.")

# Take the YYYYMMDD date format and turn it in YYYY-MM-DD
date_nice(orig::String) = string(orig[1:4],"-",orig[5:6],"-",orig[7:8])
date_nice(orig::Int) = date_nice(string(orig))

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