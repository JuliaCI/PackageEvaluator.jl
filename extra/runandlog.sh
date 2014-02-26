cd /home/idunning/PackageEvaluator.jl/extra
# Set special .julia folder just for this run
export JULIA_PKGDIR="/home/idunning/pkgtest/.julia"
# Make sure its totally empty
rm -rf $JULIA_PKGDIR
# Initialize and install PackageEvaluator
/home/idunning/julia/julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'
# Run the tester on all packages (-1) and export JSON (J)
# Log STDOUT and STDERR to a file, e.g. genresults_2014-02-25-22.log
/home/idunning/julia/julia genresults.jl -1 J 2>&1 | tee 
genresults_$(date '+%Y-%m-%d-%H').log
# Post .jsons to status.julialang.org
/home/idunning/julia/julia postresults.jl
