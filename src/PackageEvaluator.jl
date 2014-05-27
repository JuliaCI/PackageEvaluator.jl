module PackageEvaluator

# Evaluate the package itself
include("package.jl")

# Output it (featuresToJSON, getDetailsString)
include("output.jl")

#######################################################################
# Regexes to identify the license type
const LICENSES=[("MIT",[
                    r"mit license",
                    r"mit expat license",
                    r"mit \"expat\" license",
                    r"permission is hereby granted, free of charge,"]),
                ("GPL v2",[
                    r"gpl version 2",
                    r"gnu general public license\s+version 2",
                    r"gnu general public license, version 2",
                    r"free software foundation; either version 2"]),
                ("GPL v3",[
                    r"gpl version 3",
                    r"http://www.gnu.org/licenses/gpl-3.0.txt",
                    r"gnu general public license\s+version 3",
                    r"gpl v3"]),
                ("LGPL v2.1",[
                    r"lgpl version 2.1",
                    r"gnu lesser general public license\s+version 2\.1"]),
                ("LGPL v3.0",[
                    r"lgpl-3.0"
                    r"version 3 of the gnu lesser"]),
                ("BSD",         [r"bsd"]),
                ("GNU Affero",  [r"gnu affero general public license"]),
                ("Romantic WTF",[r"romantic wtf public license"])
                ]

# Possible locations of licenses
const LICFILES=["LICENSE", "LICENSE.md", "License.md", "LICENSE.txt",
                 "README",  "README.md",                "README.txt",
                "COPYING", "COPYING.md",               "COPYING.txt"]


#######################################################################
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
    addremove && Pkg.add(pkg)
  
    features = Dict{Symbol,Any}()
    features[:VERSION] = string(Pkg.installed(pkg))

    # Package
    pkg_path = Pkg.dir(pkg)
    checkLicense(features, pkg_path)
    checkTesting(features, pkg_path, pkg)
    getInfo(features, pkg_path)

    # Remove Pkg if necessary
    addremove && Pkg.rm(pkg)

    return features
end

#######################################################################
end
