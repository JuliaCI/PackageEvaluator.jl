#!/bin/sh
#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/JuliaCI/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build.sh
# Runs all the scripts in the correct sequence.
# You should edit this file for the paths on your system.
#-----------------------------------------------------------------------

set -e # stop on failure
CURDATE=$(date +%Y%m%d)

JULIA=$(which julia)
STARPATH=$HOME/github/pkg.julialang.org/db/star_db.csv
HISTPATH=$HOME/github/pkg.julialang.org/db/hist_db.csv
LOGPATH=$HOME/github/pkg.julialang.org/logs
BADGEPATH=$HOME/github/pkg.julialang.org/badges
INDPATH=$HOME/github/pkg.julialang.org/
IMGPATH=$HOME/github/pkg.julialang.org/img

gunzip -f -k $STARPATH.gz
gunzip -f -k $HISTPATH.gz

#scp nanosoldier1.csail.mit.edu:~/PkgEval/scripts/*.json ./
cp $(dirname "$0")/../scripts/*.json .

$JULIA --color=yes pull_repo_info.jl 0.4AK.json 0.4LZ.json 0.5AK.json 0.5LZ.json 0.6AK.json 0.6LZ.json

$JULIA --color=yes build_site_data.jl $LOGPATH $BADGEPATH $HISTPATH

$JULIA --color=yes update_db.jl $CURDATE $STARPATH $HISTPATH

$JULIA --color=yes build_index.jl $HISTPATH $INDPATH

$JULIA --color=yes pulse_plots.jl $STARPATH $HISTPATH $IMGPATH

$JULIA --color=yes build_pulse.jl $CURDATE $STARPATH $HISTPATH $INDPATH

gzip -f $STARPATH
gzip -f $HISTPATH
