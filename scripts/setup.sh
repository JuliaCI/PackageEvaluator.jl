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
# Install Julia and upgrade installation
sudo apt-get update    # Pull in latest versions
sudo apt-get upgrade   # Upgrade system packages
# Use first argument to distinguish between the versions
if [ "$1" == "release" ]
then
    wget -O julia03.tar.gz https://julialang.s3.amazonaws.com/bin/linux/x64/0.3/julia-0.3.6-linux-x86_64.tar.gz
    tar -zxvf julia03.tar.gz
    export PATH="${PATH}:/home/vagrant/julia03/bin/"
else
    wget -O julia04.tar.gz https://status.julialang.org/download/linux-x86_64
    tar -zxvf julia04.tar.gz
    export PATH="${PATH}:/home/vagrant/julia04/bin/"
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

#export JAVA_HOME="/usr/lib/jvm/java-7-openjdk/"

#######################################################################
# Install PackageEvaluator
julia -e "Pkg.init(); Pkg.clone(\"https://github.com/IainNZ/PackageEvaluator.jl.git\")"

# Run PackageEvaluator
# We'll tee to dummy file to swallow any error
if [ "$2" == "release" ]
then
    rm -rf /vagrant/release
    mkdir /vagrant/release
    cd /vagrant/release
    for f in /root/.julia/v0.3/METADATA/*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "releaseAL" ]
then
    rm -rf /vagrant/releaseAL
    mkdir /vagrant/releaseAL
    cd /vagrant/releaseAL
    for f in /root/.julia/v0.3/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "releaseMZ" ]
then
    rm -rf /vagrant/releaseMZ
    mkdir /vagrant/releaseMZ
    cd /vagrant/releaseMZ
    for f in /root/.julia/v0.3/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
    for f in /root/.julia/v0.3/METADATA/[a-z]*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done

elif [ "$2" == "nightly" ]
then
    rm -rf /vagrant/nightly
    mkdir /vagrant/nightly
    cd /vagrant/nightly
    for f in /root/.julia/v0.4/METADATA/*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "nightlyAL" ]
then
    rm -rf /vagrant/nightlyAL
    mkdir /vagrant/nightlyAL
    cd /vagrant/nightlyAL
    for f in /root/.julia/v0.4/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "nightlyMZ" ]
then
    rm -rf /vagrant/nightlyMZ
    mkdir /vagrant/nightlyMZ
    cd /vagrant/nightlyMZ
    for f in /root/.julia/v0.4/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
    for f in /root/.julia/v0.4/METADATA/[a-z]*;
    do
        pkgname=$(basename "$f")
        julia-debug -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
fi


# Bundle results together
echo "Bundling results"
cd /vagrant/
if [ "$2" == "release" ]
then
    julia /home/vagrant/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/release release
elif [ "$2" == "releaseAL" ]
then
    julia /home/vagrant/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/releaseAL releaseAL
elif [ "$2" == "releaseMZ" ]
then
    julia /home/vagrant/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/releaseMZ releaseMZ

elif [ "$2" == "nightly" ]
then
    julia /home/vagrant/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightly nightly
elif [ "$2" == "nightlyAL" ]
then
    julia /home/vagrant/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightlyAL nightlyAL
elif [ "$2" == "nightlyMZ" ]
then
    julia /home/vagrant/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightlyMZ nightlyMZ
fi

echo "Finished normally! $1  $2"