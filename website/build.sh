#!/bin/bash
#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/build.sh
# Runs all the scripts in the correct sequence.
# You should edit this file for the paths on your system.
#-----------------------------------------------------------------------

CURDATE=20160207

JULIA=/Users/idunning/Code/julia04/julia
STARPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/db/star_db.csv
HISTPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/db/hist_db.csv
LOGPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/logs
BADGEPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/badges
INDPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/
IMGPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/img

scp nanosoldier1.csail.mit.edu:~/PkgEval/scripts/*.json ./

$JULIA --color=yes pull_repo_info.jl 0.3AL.json 0.3MZ.json 0.4AL.json 0.4MZ.json 0.5AL.json 0.5MZ.json

$JULIA --color=yes build_site_data.jl $LOGPATH $BADGEPATH $HISTPATH

$JULIA --color=yes update_db.jl $CURDATE $STARPATH $HISTPATH

$JULIA --color=yes build_index.jl $HISTPATH $INDPATH

$JULIA --color=yes pulse_plots.jl $STARPATH $HISTPATH $IMGPATH

$JULIA --color=yes build_pulse.jl $CURDATE $STARPATH $HISTPATH $INDPATH
