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
# Can either run two machines in parallel (release & nightly)
# or four machines in parallel (release on two, nightly on two)


parallel_provision() {
    while read box; do
        echo "Provisioning '$box'. Output will be in: $box.out.txt" 1>&2
        echo $box
    done | xargs -P 2 -I"BOXNAME" \
        sh -c 'vagrant provision BOXNAME >BOXNAME.out.txt 2>&1 || echo "Error Occurred: BOXNAME"'
}

if [ "$1" == "two" ]
then
    vagrant up --no-provision release
    vagrant up --no-provision nightly

    # Provision in parallel
    cat <<EOF | parallel_provision
release
nightly
EOF

else
    vagrant up --no-provision releaseAL
    vagrant up --no-provision releaseMZ
    vagrant up --no-provision nightlyAL
    vagrant up --no-provision nightlyMZ

    # Provision in parallel
    cat <<EOF | parallel_provision
releaseAL
releaseMZ
nightlyAL
nightlyMZ
EOF

fi

# OK, we're done! Teardown VMs
vagrant destroy -f