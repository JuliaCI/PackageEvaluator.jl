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
    vagrant up --no-provision all03
    vagrant up --no-provision all04
    vagrant up --no-provision all05

    # Provision in parallel
    cat <<EOF | parallel_provision
all03
all04
all05
EOF

else
    vagrant up --no-provision halfAL03
    vagrant up --no-provision halfMZ03
    vagrant up --no-provision halfAL04
    vagrant up --no-provision halfMZ04
    vagrant up --no-provision halfAL05
    vagrant up --no-provision halfMZ05

    # Provision in parallel
    cat <<EOF | parallel_provision
halfAL03
halfMZ03
halfAL04
halfMZ04
halfAL05
halfMZ05
EOF

fi

# OK, we're done! Teardown VMs
vagrant destroy -f
