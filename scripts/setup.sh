#!/usr/bin/env bash
#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# This script file sets up the environment for running PkgEval, then
# runs it to produce the JSON result files.

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

# Run PackageEvaluator
if [ "$1" == "release" ]
then
    mkdir /vagrant/release
    cd /vagrant/release
else
    mkdir /vagrant/nightly
    cd /vagrant/nightly
fi
julia --color -e 'using PackageEvaluator; eval_pkgs(limit=5,juliapkg="./",jsonpath="./")'

# Bundle results together
if [ "$1" == "release" ]
then
    julia ~/.julia/PackageEvaluator/scripts/joinjson.jl /vagrant/release release
else
    julia ~/.julia/PackageEvaluator/scripts/joinjson.jl /vagrant/nightly nightly
fi