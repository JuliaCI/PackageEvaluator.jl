#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
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

# Special package treatments
# XVFB   = requires X virtual framebuffer
# BINARY = can't run due to a binary dependency that can't be satisfied
# OSX    = only works on OSX
# PYTHON = requires a Python package
const PKGOPTS= ["ApproxFun"     =>  :XVFB,
                "Arduino"       =>  :BINARY,
                "Arduino"       =>  :BINARY,
                "Clang"         =>  :BINARY,
                "CPLEX"         =>  :BINARY,
                "CLFFT"         =>  :BINARY,
                "CUDA"          =>  :BINARY,
                "Gaston"        =>  :XVFB,
                "GLFW"          =>  :BINARY,
                "Gtk"           =>  :BINARY,
                "Gurobi"        =>  :BINARY,
                "Homebrew"      =>  :OSX,
                "ImageView"     =>  :XVFB,
                "Mathematica"   =>  :BINARY,
                "MathProgBase"  =>  :BINARY,
                "MATLAB"        =>  :BINARY,
                "MATLABCluster" =>  :BINARY,
                "Mongo"         =>  :BINARY,
                "Mongrel2"      =>  :BINARY,
                "Mosek"         =>  :BINARY,
                "OpenCL"        =>  :BINARY,
                "OpenGL"        =>  :BINARY,
                "Pandas"        =>  :PYTHON,
                "ProfileView"   =>  :XVFB,
                "PyLexYacc"     =>  :PYTHON,
                "PyPlot"        =>  :PYTHON,
                "PySide"        =>  :PYTHON,
                "RdRand"        =>  :BINARY, # Needs latest Intel CPU
                "SemidefiniteProgramming" => :BINARY,
                "Sodium"        =>  :BINARY,
                "SymPy"         =>  :PYTHON,
                "Tk"            =>  :XVFB,
                "Winston"       =>  :XVFB,
                "Vega"          =>  :BINARY,
                "VML"           =>  :BINARY]

# Some packages have testing-only dependencies
# Long-term this should be handled by the test/REQUIRE file
const EXCEPTIONS = ["CRC"               => ["Zlib"],
                    "DecisionTree"      => ["RDatasets"],
                    "ExpressionUtils"   => ["FactCheck"],
                    "Gadfly"            => ["RDatasets", "Cairo"],
                    "GLM"               => ["DataFrames"],
                    "HTTPClient"        => ["JSON"],
                    "ImageView"         => ["TestImages"],
                    "JuMP"              => ["Cbc","Clp","GLPKMathProgInterface"],
                    "MarketTechnicals"  => ["Datetime", "FactCheck","MarketData"],
                    "MarketData"        => ["FactCheck"],
                    "MathProgBase"      => ["Cbc", "Clp"],
                    "PLX"               => ["BinDeps", "MAT"],
                    "Synchrony"         => ["CrossDecomposition"],
                    "TimeModels"        => ["FactCheck", "MarketData"],
                    "TimeSeries"        => ["Datetime", "FactCheck", "MarketData"]
                    ]