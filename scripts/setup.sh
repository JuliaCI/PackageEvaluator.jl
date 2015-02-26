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
# 2: The test set to run: release | nightly | releaseAL | releaseMZ | nightlyAL | nightlyMZ
#######################################################################

# Accept all apt-gets
# This is an attempt to deal with BinDeps packages trying to
# install dependencies with apt-get
# Otherwise seem to get things like
#   After this operation, 6,203 kB of additional disk space will be used.
#    Do you want to continue? [Y/n] Abort.
# appearing in output.
sudo su
cat >/etc/apt/apt.conf.d/pkgevalforceyes <<EOL
APT::Get::Assume-Yes "true";
APT::Get::force-yes "true";
EOL

# Install Julia and make result folders
if [ "$1" == "release" ]
then
    add-apt-repository ppa:staticfloat/juliareleases
else
    add-apt-repository ppa:staticfloat/julianightlies
fi
add-apt-repository ppa:staticfloat/julia-deps
apt-get update
apt-get install julia


# Install any dependencies
apt-get install xvfb
#export JAVA_HOME="/usr/lib/jvm/java-7-openjdk/"
exit  # from su

# Install PackageEvaluator
julia -e "Pkg.init(); Pkg.clone(\"https://github.com/IainNZ/PackageEvaluator.jl.git\")"


# Run package evaluator
# We'll tee to dummy file to swallow any error
if [ "$2" == "release" ]
then
    rm -rf /vagrant/release
    mkdir /vagrant/release
    cd /vagrant/release
    for f in /root/.julia/v0.3/METADATA/*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "releaseAL" ]
then
    rm -rf /vagrant/releaseAL
    mkdir /vagrant/releaseAL
    cd /vagrant/releaseAL
    for f in /root/.julia/v0.3/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "releaseMZ" ]
then
    rm -rf /vagrant/releaseMZ
    mkdir /vagrant/releaseMZ
    cd /vagrant/releaseMZ
    for f in /root/.julia/v0.3/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
    for f in /root/.julia/v0.3/METADATA/[a-z]*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done

elif [ "$2" == "nightly" ]
then
    rm -rf /vagrant/nightly
    mkdir /vagrant/nightly
    cd /vagrant/nightly
    for f in /root/.julia/v0.4/METADATA/*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "nightlyAL" ]
then
    rm -rf /vagrant/nightlyAL
    mkdir /vagrant/nightlyAL
    cd /vagrant/nightlyAL
    for f in /root/.julia/v0.4/METADATA/[A-L]*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
elif [ "$2" == "nightlyMZ" ]
then
    rm -rf /vagrant/nightlyMZ
    mkdir /vagrant/nightlyMZ
    cd /vagrant/nightlyMZ
    for f in /root/.julia/v0.4/METADATA/[M-Z]*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
    for f in /root/.julia/v0.4/METADATA/[a-z]*;
    do
        pkgname=$(basename "$f")
        julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    done
fi


# Bundle results together
if [ "$2" == "release" ]
then
    julia /root/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/release release
elif [ "$2" == "releaseAL" ]
then
    julia /root/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/releaseAL releaseAL
elif [ "$2" == "releaseMZ" ]
then
    julia /root/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/releaseMZ releaseMZ

elif [ "$2" == "nightly" ]
then
    julia /root/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightly nightly
elif [ "$2" == "nightlyAL" ]
then
    julia /root/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightlyAL nightlyAL
elif [ "$2" == "nightlyMZ" ]
then
    julia /root/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightlyMZ nightlyMZ
fi

echo "Finished normally! $1  $2"