export JULIA_PKGDIR="/mnt/ram/.julia"
rm -rf /mnt/ram/.julia
julia -e 'Pkg.init(); Pkg.clone("https://github.com/IainNZ/PackageEvaluator.jl.git")'
time julia genresults.jl 2>&1 | tee genresults_$(date '+%Y-%m-%d-%H').log
