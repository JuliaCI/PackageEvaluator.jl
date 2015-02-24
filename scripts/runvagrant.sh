#!/usr/bin/env bash
#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# This script launches the Vagrant VMs in parallel, because all the
# work happens during provisioning.
# Based off of
#  http://server.dzone.com/articles/parallel-provisioning-speeding


parallel_provision() {
    while read box; do
        echo "Provisioning '$box'. Output will be in: $box.out.txt" 1>&2
        echo $box
    done | xargs -P 2 -I"BOXNAME" \
        sh -c 'vagrant provision BOXNAME >BOXNAME.out.txt 2>&1 || echo "Error Occurred: BOXNAME"'
}
 
# Start boxes sequentially
# Apparently avoids VirtualBox problems
vagrant up --no-provision
 
# Provision in parallel
cat <<EOF | parallel_provision
release
nightly
EOF

# OK, we're done! Teardown VMs