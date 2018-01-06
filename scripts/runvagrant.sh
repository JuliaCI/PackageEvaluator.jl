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
# Can either run two or six machines in parallel
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

if [ "$1" == "two" ]
then
    vagrant up --no-provision all06
    vagrant up --no-provision all07

    # Provision in parallel
    cat <<EOF | parallel_provision
all06
all07
EOF

else
    vagrant up --no-provision thirdAF06
    vagrant up --no-provision thirdGO06
    vagrant up --no-provision thirdPZ06
    vagrant up --no-provision thirdAF07
    vagrant up --no-provision thirdGO07
    vagrant up --no-provision thirdPZ07

    # Provision in parallel
    cat <<EOF | parallel_provision
thirdAF06
thirdGO06
thirdPZ06
thirdAF07
thirdGO07
thirdPZ07
EOF

fi

# OK, we're done! Teardown VMs
vagrant destroy -f
