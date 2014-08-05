# Assume we are in /PackageEvaluator/extra/
cd nightly
julia -e 'using PackageEvaluator; testAllPkgs(limit=5,usetimeout=false)'
cd ..
julia concat.jl