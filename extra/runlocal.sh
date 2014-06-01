# Assume we are in /PackageEvaluator/extra/

# Run the tester on all packages
# Log STDOUT and STDERR to a file, e.g. genresults_2014-02-25-22.log
cd nightly
julia -e 'using PackageEvaluator; testAllPkgs(10)' 2>&1 | tee pkgeval_$(date '+%Y-%m-%d-%H').log

# Post .jsons to status.julialang.org
#julia ../postresults.jl