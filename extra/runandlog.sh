export PKGEVALEXTRA="/home/idunning/PackageEvaluator.jl/extra"
cd $PKGEVALEXTRA

# Set special .julia folder just for this run
export JULIA_PKGDIR="/home/idunning/pkgtest/.julia"

# Make sure we know where Julia stable is (for cron job)
export ORIGPATH="$PATH"
export PATH="$PATH:/home/idunning/julia"

# Make sure test directory is totally empty
rm -rf /home/idunning/pkgtest
mkdir /home/idunning/pkgtest

# Initialize and install PackageEvaluator in JULIA_PKGDIR
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'

# Run the tester on all packages (-1) and export JSON (J)
# Log STDOUT and STDERR to a file, e.g. genresults_2014-02-25-22.log
julia genresults.jl -1 J 2>&1 | tee genresults_$(date '+%Y-%m-%d-%H').log

# Post .jsons to status.julialang.org
julia postresults.jl

echo "############# DONE WITH 0.2"

# Now we need to switch to nightly
# Script needs Python 2 and requests installed
cd /home/idunning/pkgtest
git clone https://github.com/JuliaLang/julia.git
cd julia
export LASTGOODCOMMIT="$(python2 $PKGEVALEXTRA/get_last_good_commit.py)"
git checkout $LASTGOODCOMMIT
make
export PATH="$ORIGPATH:/home/idunning/pkgtest/julia"
echo $PATH
cd $PKGEVALEXTRA

# Initialize and install PackageEvaluator in JULIA_PKGDIR (v0.3 now)
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'

# Run the tester on all packages (-1) and export JSON (J)
# Log STDOUT and STDERR to a file, e.g. genresultsnightly_2014-02-25-22.log
julia genresults.jl -1 J 2>&1 | tee genresultsnightly_$(date '+%Y-%m-%d-%H').log

# Post .jsons to status.julialang.org
julia postresults.jl

