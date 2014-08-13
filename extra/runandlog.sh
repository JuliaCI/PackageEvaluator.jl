#######################################################################
# PackageEvaluator
# Nightly test script run on a headless Arch Linux box at MIT
#######################################################################
# Set up environmental variables and folders
#######################################################################
export TESTHOME="/home/idunning"
export ORIGPATH="${PATH}"
# For Java packages
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk/"
# Where the run script is, and where results will be stored
export PKGEVALEXTRA="${TESTHOME}/PackageEvaluator.jl/extra"
cd $PKGEVALEXTRA
# Set special .julia folder just for testing
export PKGTEST_DIR="${TESTHOME}/pkgtest"
export JULIA_PKGDIR="${PKGTEST_DIR}/.julia"
# Make sure test directory is totally empty
rm -rf $PKGTEST_DIR
mkdir $PKGTEST_DIR
# The Julia directories
export STABLE_DIR="${TESTHOME}/julia03"
export NIGHTLY_DIR="${TESTHOME}/julia04"

#######################################################################
# JULIA STABLE (not compiled nightly)
#######################################################################
echo "############# STARTING STABLE"
# Install PackageEvaluator
export PATH="${ORIGPATH}:${STABLE_DIR}"
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'
# Run it, save results in stable/ folder
cd stable
julia -e 'using PackageEvaluator; testAllPkgs()'
echo "############# DONE STABLE"


#######################################################################
# JULIA NIGHTLY (compiled nightly)
#######################################################################
# Download Julia master
rm -rf $NIGHTLY_DIR
mkdir $NIGHTLY_DIR
cd $NIGHTLY_DIR
git clone https://github.com/JuliaLang/julia.git .
# Checkout last working commit
export LASTGOODCOMMIT="$(python2 ${PKGEVALEXTRA}/get_last_good_commit.py)"
git checkout $LASTGOODCOMMIT
# Fix for this specific Arch machine
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
cd $PKGEVALEXTRA
cd nightly
julia -e 'using PackageEvaluator; testAllPkgs()'
echo "############# DONE NIGHTLY"


#######################################################################
# Bundle all results into one JSON
#######################################################################
echo "############# BUNDLING"
cd ..
julia concat.jl
echo "############# DONE BUNDLING"