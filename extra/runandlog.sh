#######################################################################
# PackageEvaluator
# Nightly test script run on a headless Arch Linux box at MIT
#######################################################################
# Set up environmental variables and folders
#######################################################################
export ORIGPATH="${PATH}"
# For Java packages
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk/
# Where the run script is, and where results will be stored
export PKGEVALEXTRA="/home/idunning/PackageEvaluator.jl/extra"
cd $PKGEVALEXTRA
# Set special .julia folder just for testing
export PKGTEST_DIR="/home/idunning/pkgtest"
export JULIA_PKGDIR="${PKGTEST_DIR}/.julia"
# Make sure test directory is totally empty
rm -rf $PKGTEST_DIR
mkdir $PKGTEST_DIR
# The nightly Julia directory
export NIGHTLY_DIR="/home/idunning/julia03"

#######################################################################
# JULIA STABLE (version 0.2.1)
# Binary path: /home/idunning/julia02           (not compiled nightly)
# Packages in: /home/idunning/pkgtest/v0.2
#######################################################################
echo "############# STARTING STABLE"
# Install PackageEvaluator
export PATH="${ORIGPATH}:/home/idunning/julia02"
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'
# Log STDOUT and STDERR to genresults_YYYY-MM-DD-HH.log in stable/
# Also tee to STDOUT so cronlog can take a look
cd stable
julia -e 'using PackageEvaluator; testAllPkgs()' 2>&1 | tee pkgeval_$(date '+%Y-%m-%d-%H').log
# Bundle into JSONs
julia ../postresults.jl
echo "############# DONE STABLE"


#######################################################################
# JULIA NIGHTLY (version 0.3-pre)
# Binary path: /home/idunning/julia03           (compiled nightly)
# Packages in: /home/idunning/pkgtest/v0.3
#######################################################################
# Download Julia master
rm -rf $NIGHTLY_DIR
mkdir $NIGHTLY_DIR
cd $NIGHTLY_DIR
git clone https://github.com/JuliaLang/julia.git .
# Checkout last working commit
export LASTGOODCOMMIT="$(python2 ${PKGEVALEXTRA}/get_last_good_commit.py)"
git checkout $LASTGOODCOMMIT
# Fix for this specific box
echo "USE_SYSTEM_PCRE = 1" > Make.user
# Try more than once if it fails to build (not sure if this works)
make
if [[ ! -f "./julia" ]]; then 
  make distcleanall
fi
if [[ ! -f "./julia" ]]; then 
  make distcleanall
fi

echo "############# STARTING NIGHTLY"
# Install PackageEvaluator
export PATH="${ORIGPATH}:${NIGHTLY_DIR}"
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'
# Log STDOUT and STDERR to genresults_YYYY-MM-DD-HH.log in stable/
# Also tee to STDOUT so cronlog can take a look
cd $PKGEVALEXTRA
cd nightly
julia -e 'using PackageEvaluator; testAllPkgs()' 2>&1 | tee pkgeval_$(date '+%Y-%m-%d-%H').log
# Bundle into JSONs
julia ../postresults.jl
echo "############# DONE NIGHTLY"