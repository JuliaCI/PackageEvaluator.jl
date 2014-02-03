module PackageEvaluator

# Evaluate the package itself
include("package.jl")

# Evaluate the metadata entry
include("metadata.jl")

# Score it (scorePkg)
include("score.jl")

# Output it (featuresToJSON, getDetailsString)
include("output.jl")

###############################################################################
# evalPkg
# Performs all tests on a single package.
# Input:
#   pkg                 Name of the package (without .jl)
#   addremove=true      If true, adds then removes the package.
#                       If false, the package needs to be in .julia
#                       and in .julia/METADATA/
# Output:
#   features            A dictionary of test results
export evalPkg
function evalPkg(pkg, addremove=true)
  # Need to add Pkg first
  if addremove
    Pkg.add(pkg)
  end
  
  features = Dict{Symbol,Any}()

  # Package
  pkg_path = Pkg.dir(pkg)
  checkREQUIRE(features, pkg_path)
  checkLicense(features, pkg_path)
  checkTesting(features, pkg_path, pkg)
  getInfo(features, pkg_path)
  
  # Metadata
  metadata_path = joinpath(ENV["HOME"],".julia","METADATA",pkg)
  checkURL(features, metadata_path)
  checkDesc(features, metadata_path)
  checkRequire(features, metadata_path)

  # Remove Pkg if necessary
  if addremove
    Pkg.rm(pkg)
  end

  # Return a dictionary of test results
  return features
end

end
