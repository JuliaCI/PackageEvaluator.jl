# Assume we are in /PackageEvaluator/extra/
cd nightly
julia -e 'using PackageEvaluator; testAllPkgs(limit=10,usetimeout=false)'
julia ../concat.jl