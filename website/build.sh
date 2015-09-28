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

CURDATE=20150927

JULIA=/Users/idunning/Code/julia04/julia

#$JULIA pull_repo_info.jl 0.3AL.json 0.3MZ.json 0.4AL.json 0.4MZ.json

STARPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/db/star_db.csv
HISTPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/db/hist_db.csv
#$JULIA update_db.jl $CURDATE $STARPATH $HISTPATH

LOGPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/logs
BADGEPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/badges
#$JULIA build_site_data.jl $LOGPATH $BADGEPATH

INDPATH=/Users/idunning/Dropbox/Websites/packages.julialang.org/index.html
#$JULIA build_index.jl $HISTPATH $INDPATH

#$JULIA pulse_plots.jl $STARPATH $HISTPATH ./