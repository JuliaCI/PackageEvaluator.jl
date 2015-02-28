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
    mkdir julia03
    tar -zxvf julia03.tar.gz -C ./julia03 --strip-components=1
    export PATH="${PATH}:/home/vagrant/julia03/bin/"
else
    wget -O julia04.tar.gz https://status.julialang.org/download/linux-x86_64
    mkdir julia04
    tar -zxvf julia04.tar.gz -C ./julia04 --strip-components=1
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
# Need GMP for e.g. GLPK, why not get some PCRE too
sudo apt-get install libpcre3-dev libgmp-dev 
# Set Java path for e.g. Taro
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk/"

#######################################################################
# Install PackageEvaluator
julia -e "Pkg.init(); Pkg.clone(\"https://github.com/IainNZ/PackageEvaluator.jl.git\")"

# Run PackageEvaluator
# We'll tee to dummy file to swallow any error
rm -rf /vagrant/$2
mkdir /vagrant/$2
cd /vagrant/$2
JULIA_PKGDIR="./" julia -e "Pkg.init(); println(Pkg.dir())"
if [ "$2" == "release" ]
then
    for f in /home/vagrant/.julia/v0.3/METADATA/*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR="./" julia -e "Pkg.add(\"${pkgname}\")"
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR="./" julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "releaseAL" ]
then
    for f in /home/vagrant/.julia/v0.3/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR="./" julia -e "Pkg.add(\"${pkgname}\")"
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR="./" julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "releaseMZ" ]
then
    for f in /home/vagrant/.julia/v0.3/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR="./" julia -e "Pkg.add(\"${pkgname}\")"
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR="./" julia -e "Pkg.rm(\"${pkgname}\")"
    done

elif [ "$2" == "nightly" ]
then
    for f in /home/vagrant/.julia/v0.4/METADATA/*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR="./" julia -e "Pkg.add(\"${pkgname}\")"
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR="./" julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "nightlyAL" ]
then
    for f in /home/vagrant/.julia/v0.4/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR="./" julia -e "Pkg.add(\"${pkgname}\")"
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR="./" julia -e "Pkg.rm(\"${pkgname}\")"
    done
elif [ "$2" == "nightlyMZ" ]
then
    for f in /home/vagrant/.julia/v0.4/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        JULIA_PKGDIR="./" julia -e "Pkg.add(\"${pkgname}\")"
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
        JULIA_PKGDIR="./" julia -e "Pkg.rm(\"${pkgname}\")"
    done
fi


# Bundle results together
echo "Bundling results"
cd /vagrant/
julia /home/vagrant/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/$2 $2


echo "Finished normally! $1  $2"