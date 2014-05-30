# Assume we are in /PackageEvaluator/extra/

# Set special .julia folder just for this run
# Make sure test directory is totally empty
export PKGTEST_DIR="/home/idunning/pkgtest"
rm -rf $PKGTEST_DIR
mkdir $PKGTEST_DIR

# Initialize and install PackageEvaluator in JULIA_PKGDIR
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git"); Pkg.checkout("PackageEvaluator","tidy")'

# Run the tester on all packages
# Log STDOUT and STDERR to a file, e.g. genresults_2014-02-25-22.log
cd nightly
julia -e 'using PackageEvaluator; testAllPkgs(10)' 2>&1 | tee pkgeval_$(date '+%Y-%m-%d-%H').log

# Post .jsons to status.julialang.org
#julia ../postresults.jl