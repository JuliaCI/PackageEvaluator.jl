#!/usr/bin/env bash
#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# This script launches the Vagrant VMs in parallel, because all the
# work happens during provisioning. Afterwards, it tears them down.
# Based off of
#  http://server.dzone.com/articles/parallel-provisioning-speeding
# Can either run two or four machines in parallel

rm -rf ./0.3*
rm -rf ./0.4*

parallel_provision() {
    while read box; do
        echo "Provisioning '$box'. Output will be in: $box.out.txt" 1>&2
        echo $box
    done | xargs -P 4 -I"BOXNAME" \
        sh -c 'vagrant provision BOXNAME >BOXNAME.out.txt 2>&1 || echo "Error Occurred: BOXNAME"'
}

if [ "$1" == "two" ]
then
    vagrant up --no-provision ALL03
    vagrant up --no-provision ALL04

    # Provision in parallel
    cat <<EOF | parallel_provision
ALL03
ALL04
EOF

else
    vagrant up --no-provision HALFAL03
    vagrant up --no-provision HALFMZ03
    vagrant up --no-provision HALFAL04
    vagrant up --no-provision HALFMZ04

    # Provision in parallel
    cat <<EOF | parallel_provision
HALFAL03
HALFMZ03
HALFAL04
HALFMZ04
EOF

fi

# OK, we're done! Teardown VMs
vagrant destroy -f
