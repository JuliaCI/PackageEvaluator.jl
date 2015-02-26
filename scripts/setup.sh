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
sudo su -c 'echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/pkgevalforceyes'
sudo su -c 'echo "APT::Get::force-yes \"true\";" >> /etc/apt/apt.conf.d/pkgevalforceyes'
#cat /etc/apt/apt.conf.d/pkgevalforceyes  # DEBUG


# Install Julia
if [ "$1" == "release" ]
then
    sudo add-apt-repository ppa:staticfloat/juliareleases
else
    sudo add-apt-repository ppa:staticfloat/julianightlies
fi
sudo add-apt-repository ppa:staticfloat/julia-deps
sudo apt-get update
echo "About to install Julia ${1}"
sudo apt-get install julia
echo "Julia installed!"

# Install any dependencies
sudo apt-get install xvfb
# Cairo.jl
#sudo apt-get install libcairo2 libfontconfig1 libpango1.0-0 libglib2.0-0 libpng12-0 libpixman-1-0 gettext
# Images.jl
#sudo apt-get install libmagickwand5
# AudioIO.jl
#sudo apt-get install portaudio19-dev
#sudo apt-get install libsndfile1-dev

#export JAVA_HOME="/usr/lib/jvm/java-7-openjdk/"


# Install PackageEvaluator
julia -e "Pkg.init(); Pkg.clone(\"https://github.com/IainNZ/PackageEvaluator.jl.git\")"

# Run PackageEvaluator
# We'll tee to dummy file to swallow any error
if [ "$2" == "release" ]
then
    rm -rf /vagrant/release
    mkdir /vagrant/release
    cd /vagrant/release
    #julia -e "run( `julia -e 'Pkg.add(\"Cairo\")' ` )"
    julia -e "using PackageEvaluator; eval_pkg(\"Cairo\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    julia -e "using PackageEvaluator; eval_pkg(\"ICU\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    julia -e "using PackageEvaluator; eval_pkg(\"Images\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    #for f in /root/.julia/v0.3/METADATA/*;
    #do
    #    pkgname=$(basename "$f")
    #    julia -e "using PackageEvaluator; eval_pkg(\"${pkgname}\",juliapkg=\"./\",jsonpath=\"./\")" | tee catcherr
    #done
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