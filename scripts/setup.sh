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

# Install Julia and make result folders
if [ "$1" == "release" ]
then
    add-apt-repository ppa:staticfloat/juliareleases
else
    add-apt-repository ppa:staticfloat/julianightlies
fi
add-apt-repository ppa:staticfloat/julia-deps
apt-get update
apt-get --yes --force-yes install julia

# Install any dependencies

# For Java packages
#export JAVA_HOME="/usr/lib/jvm/java-7-openjdk/"

# Install and run PackageEvaluator
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'
julia -e 'Pkg.checkout("PackageEvaluator","rewrite")'
if [ "$1" == "release" ]
then
    rm -rf /vagrant/release
    mkdir /vagrant/release
    cd /vagrant/release
else
    rm -rf /vagrant/nightly
    mkdir /vagrant/nightly
    cd /vagrant/nightly
fi
julia -e 'using PackageEvaluator; eval_pkgs(juliapkg="./",jsonpath="./")'

# Bundle results together
if [ "$1" == "release" ]
then
    julia /root/.julia/v0.3/PackageEvaluator/scripts/joinjson.jl /vagrant/release release
else
    julia /root/.julia/v0.4/PackageEvaluator/scripts/joinjson.jl /vagrant/nightly nightly
fi