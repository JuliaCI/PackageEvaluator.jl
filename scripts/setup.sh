#!/usr/bin/env bash
#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning and contributors 2015
# Licensed under the MIT License
#######################################################################
# This script file is the provisioning script run by Vagrant after
# the VM is created. It sets up the environment for running PkgEval,
# then runs it to produce the JSON result files.
#
# Commandline arguments for this script, passed through by Vagrant.
# 1st: Julia version: release | nightly
# 2nd: Test set to run: release | releaseAL | releaseMZ |
#                       nightly | nightlyAL | nightlyMZ
#######################################################################


#######################################################################
# Accept all apt-gets
# This is an attempt to deal with BinDeps packages trying to install
# dependencies with apt-get and asking for permissions. Normally we
# could pass a --yes argument to avoid this, but there isn't a way to
# do that with BinDeps. We can actually do a global override, which
# is what we do here. Since we are piping stuff into a file, the
# easiest way to sudo the whole thing is to do it in this style.
sudo su -c 'echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/pkgevalforceyes'
sudo su -c 'echo "APT::Get::force-yes \"true\";" >> /etc/apt/apt.conf.d/pkgevalforceyes'
# Uncomment following line to check it did indeed work
#cat /etc/apt/apt.conf.d/pkgevalforceyes


#######################################################################
# Upgrade the installation and install Julia 
sudo apt-get update    # Pull in latest versions
sudo apt-get upgrade   # Upgrade system packages
# Use first argument to script to distinguish between the versions
if [ "$1" == "release" ]
then
    wget -O julia.tar.gz https://julialang.s3.amazonaws.com/bin/linux/x64/0.3/julia-0.3-latest-linux-x86_64.tar.gz
else
    wget -O julia.tar.gz https://status.julialang.org/download/linux-x86_64
fi
mkdir julia
tar -zxvf julia.tar.gz -C ./julia --strip-components=1
export PATH="${PATH}:/home/vagrant/julia/bin/"
# Retain PATH to make it easier to use VM for debugging
echo "export PATH=\"\${PATH}:/home/vagrant/julia/bin/\"" >> /home/vagrant/.profile


#######################################################################
# Install any dependencies that aren't handled by BinDeps
# Somethings can't be or don't make sense to be installed by BinDeps,
# so we will do them manually. Package maintainers can submit PRs to
# extend this list as needed.
# Need git of course, doesn't come by default in the image
sudo apt-get install git
# Need X virtual frame buffer for many packages
sudo apt-get install xvfb
# Need GMP for e.g. GLPK, why not get some PCRE too
sudo apt-get install libpcre3-dev libgmp-dev
# Need gfortran for e.g. GLMNet.jl, Ipopt.jl, KernSmooth.jl...
sudo apt-get install gfortran pkg-config
# Need unzip for e.g. Blink.jl, FLANN.jl
sudo apt-get install unzip
# Need cmake for e.g. GLFW.jl, Metis.jl
sudo apt-get install cmake
# Install R for e.g. Rif.jl, RCall.jl
sudo apt-get install r-base r-base-dev 
# Install Java for e.g. JavaCall.jl, Taro.jl
# From: http://stackoverflow.com/q/19275856/3822752
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install oracle-java7-installer
export JAVA_HOME=/usr/lib/jvm/java-7-oracle
echo "export JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /home/vagrant/.profile
# Install matplotlib for PyPlot.jl
sudo apt-get install python-matplotlib
# Install xlrd for ExcelReaders.jl
sudo apt-get install python-pip
sudo pip install xlrd
# Install SymPy
sudo pip install sympy


#######################################################################
# Install PackageEvaluator and prepare to run
julia -e "Pkg.init(); Pkg.clone(\"https://github.com/IainNZ/PackageEvaluator.jl.git\")"
# Make results folders. Folder name is second argument to this script.
# These folders are shared - i.e. we are writing to outside the VM,
# most likely the PackageEvaluator.jl/scripts folder.
rm -rf /vagrant/$2
mkdir /vagrant/$2
cd /vagrant/$2
# Make folder for where tested packages should go.
# We could use the default, but then it gets messy because that is
# where PackageEvaluator itself lives (and its dependencies).
# Its important for it to not be in the /vagrant/ folder as hat seems
# to mess with symlinks quite badly.
# See https://github.com/JuliaOpt/Ipopt.jl/issues/31 for discussion
# about this breaking a build.
TESTPKG="/home/vagrant/testpkg"
mkdir $TESTPKG
# Initialize METADATA for testing
JULIA_PKGDIR=$TESTPKG julia -e "Pkg.init(); println(Pkg.dir())"


#######################################################################
# Run PackageEvaluator
if [ "$2" == "release" ]
then
    # For every package name...
    for f in /home/vagrant/.julia/v0.3/METADATA/*;
    do
        # Extract just the package name from the path
        PKGNAME=$(basename "$f")
        # Attempt to add the package. We give it half an hour - most
        # use far less, some do push it. CoinOptServices.jl set the
        # standard for build time and memory consumption, see
        # https://github.com/IainNZ/PackageEvaluator.jl/issues/83
        # The log for adding the package will go in the results folder.
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${PKGNAME}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${PKGNAME}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        # Finish up by removing the package. Doesn't actually remove
        # it in the sense of deleting the files - this helps the
        # overall process run faster, if my understanding of how
        # the .trash folder works is correct.
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${PKGNAME}\")"
    done
elif [ "$2" == "releaseAL" ]
then
    for f in /home/vagrant/.julia/v0.3/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${pkgname}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "releaseMZ" ]
then
    for f in /home/vagrant/.julia/v0.3/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${pkgname}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${pkgname}\")"
    done

elif [ "$2" == "nightly" ]
then
    for f in /home/vagrant/.julia/v0.4/METADATA/*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${pkgname}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "nightlyAL" ]
then
    for f in /home/vagrant/.julia/v0.4/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${pkgname}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "nightlyMZ" ]
then
    for f in /home/vagrant/.julia/v0.4/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${pkgname}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${pkgname}\")"
    done
fi


#######################################################################
# Bundle results together
echo "Bundling results"
cd /vagrant/
if [ "$1" == "release" ]
then
    julia /home/vagrant/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/$2 $2
else
    julia /home/vagrant/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/$2 $2
fi


#######################################################################
echo "Finished normally! $1  $2"