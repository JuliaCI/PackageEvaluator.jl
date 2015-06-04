#!/usr/bin/env bash
#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# This script file is the provisioning script run by Vagrant after
# the VM is created. It sets up the environment for running PkgEval,
# then runs it to produce the JSON result files.
#
# Commandline arguments
# 1: The Julia version: release | nightly
# 2: The test set to run: release | releaseAL | releaseMZ |
#                         nightly | nightlyAL | nightlyMZ
#######################################################################


#######################################################################
# Accept all apt-gets
# This is an attempt to deal with BinDeps packages trying to install
# dependencies with apt-get and asking for permissions. Normally we
# could pass a --yes argument to avoid this, but there isn't a way to
# do that with BinDpes. We can actually do a global override, which
# is what we do here. Since we are piping stuff into a file, the
# easiest way to sudo the whole thing is to do it in this style.
sudo su -c 'echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/pkgevalforceyes'
sudo su -c 'echo "APT::Get::force-yes \"true\";" >> /etc/apt/apt.conf.d/pkgevalforceyes'
# Uncomment following line to check it did indeed work
#cat /etc/apt/apt.conf.d/pkgevalforceyes

#######################################################################
# Upgrade installation and install Julia and 
sudo apt-get update    # Pull in latest versions
sudo apt-get upgrade   # Upgrade system packages
# Use first argument to distinguish between the versions
if [ "$1" == "release" ]
then
    wget -O julia03.tar.gz https://julialang.s3.amazonaws.com/bin/linux/x64/0.3/julia-0.3.9-linux-x86_64.tar.gz
    mkdir julia03
    tar -zxvf julia03.tar.gz -C ./julia03 --strip-components=1
    export PATH="${PATH}:/home/vagrant/julia03/bin/"
    # Retain PATH to make it easier to use VM for debugging
    echo "export PATH=\"\${PATH}:/home/vagrant/julia03/bin/\"" >> /home/vagrant/.profile
else
    wget -O julia04.tar.gz https://status.julialang.org/download/linux-x86_64
    mkdir julia04
    tar -zxvf julia04.tar.gz -C ./julia04 --strip-components=1
    export PATH="${PATH}:/home/vagrant/julia04/bin/"
    # Retain PATH to make it easier to use VM for debugging
    echo "export PATH=\"\${PATH}:/home/vagrant/julia04/bin/\"" >> /home/vagrant/.profile
fi

#######################################################################
# Install any dependencies that aren't handled by BinDeps
# Somethings can't be or don't make sense to be installed by BinDeps,
# so we will do them manually. Package maintainers can submit PRs to
# extend this list as needed.
# Need git of course, doesn't come by default
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

#######################################################################
# Install PackageEvaluator
julia -e "Pkg.init(); Pkg.clone(\"https://github.com/IainNZ/PackageEvaluator.jl.git\")"

# Run PackageEvaluator
# We'll tee to dummy file to swallow any error
# Make results folders
rm -rf /vagrant/$2
mkdir /vagrant/$2
cd /vagrant/$2
# Make folder for where tested packages should go
# Note that its important for it to not be in the /vagrant/
# folder as that seems to mess with symlinks quite badly
# See https://github.com/JuliaOpt/Ipopt.jl/issues/31
TESTPKG="/home/vagrant/testpkg"
mkdir $TESTPKG
# Initialize METADATA for testing
JULIA_PKGDIR=$TESTPKG julia -e "Pkg.init(); println(Pkg.dir())"
if [ "$2" == "release" ]
then
    for f in /home/vagrant/.julia/v0.3/METADATA/*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR=$TESTPKG timeout 1800s julia -e "Pkg.add(\"${pkgname}\")" 2>&1 | tee PKGEVAL_${pkgname}_add.log
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",loadpkgadd=true,juliapkg=\"${TESTPKG}\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR=$TESTPKG julia -e "Pkg.rm(\"${pkgname}\")"
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


# Bundle results together
echo "Bundling results"
cd /vagrant/
if [ "$1" == "release" ]
then
    julia /home/vagrant/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/$2 $2
else
    julia /home/vagrant/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/$2 $2
fi


echo "Finished normally! $1  $2"
