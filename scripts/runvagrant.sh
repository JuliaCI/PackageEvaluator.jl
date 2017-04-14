#!/usr/bin/env bash
#######################################################################
# PackageEvaluator
# https://github.com/JuliaCI/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# This script launches the Vagrant VMs in parallel, because all the
# work happens during provisioning. Afterwards, it tears them down.
# Based off of
#  http://server.dzone.com/articles/parallel-provisioning-speeding
# Can either run three or six machines in parallel
#######################################################################

# Remove results from previous runs
./clean.sh

parallel_provision() {
    while read box; do
        echo "Provisioning '$box'. Output will be in: $box.out.txt" 1>&2
        echo $box
    done | xargs -P 6 -I"BOXNAME" \
        sh -c 'vagrant provision BOXNAME >BOXNAME.out.txt 2>&1 || echo "Error Occurred: BOXNAME"'
}

if [ "$1" == "three" ]
then
    vagrant up --no-provision all04
    vagrant up --no-provision all05
    vagrant up --no-provision all06

    # Provision in parallel
    cat <<EOF | parallel_provision
all04
all05
all06
EOF

else
    vagrant up --no-provision halfAK04
    vagrant up --no-provision halfLZ04
    vagrant up --no-provision halfAK05
    vagrant up --no-provision halfLZ05
    vagrant up --no-provision halfAK06
    vagrant up --no-provision halfLZ06

    # Provision in parallel
    cat <<EOF | parallel_provision
halfAK04
halfLZ04
halfAK05
halfLZ05
halfAK06
halfLZ06
EOF

fi

# OK, we're done! Teardown VMs
vagrant destroy -f
