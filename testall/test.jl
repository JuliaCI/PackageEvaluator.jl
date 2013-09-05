# Load in package evaluator
require("../src/PackageEvaluator.jl")
using PackageEvaluator

# First step, nuke the .julia folder
home = "/home/idunning"
run(`rm -rf $home/.julia`)
run(`rm -rf METADATA.jl`)

# Download METADATA to the local folder
run(`git clone https://github.com/JuliaLang/METADATA.jl.git`)
cd("METADATA.jl")
run(`git checkout devel`)
cd("..")

# Walk through each package
# For now cheat and cherry pick one
pkg_name = "Distributions"

# Add the package and its dependencies
Pkg.add(pkg_name)

# Run PackageEvaluator
evalPkg("$home/.julia/$pkg_name", "METADATA.jl/$pkg_name")

# Run the packages tests
try
  let
    include("$home/.julia/$pkg_name/run_tests.jl")
  end
catch
  println("Failed some tests!")
end

# Clean up
run(`rm -rf $home/.julia`)
