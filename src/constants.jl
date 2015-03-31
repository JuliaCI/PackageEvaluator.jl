#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
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
                    r"gpl ?v2",
                    r"gnu general public license\s+version 2",
                    r"gnu general public license, version 2",
                    r"free software foundation; either version 2"]),
                ("GPL v3",[
                    r"gpl version 3",
                    r"gpl ?v3",
                    r"http://www.gnu.org/licenses/gpl-3.0.txt",
                    r"gnu general public license\s+version 3",
                    r"free software foundation, either version 3"]),
                ("LGPL v2.1",[
                    r"lgpl version 2.1",
                    r"gnu lesser general public license\s+version 2\.1"]),
                ("LGPL v3.0",[
                    r"lgpl-3.0"
                    r"version 3 of the gnu lesser"]),
                ("BSD 3-clause",[r"bsd", r"promote products derived from this software"]),
                ("BSD 2-clause",[r"bsd", r"other materials provided with the\s+distribution.\s+this software"]),
                ("GNU Affero",  [r"gnu affero general public license"]),
                ("Apache",      [r"apache"]),
                ("zlib",        [r"zlib", r"the origin of this software must not be misrepresented"]),
                ("ISC",         [r"permission to use, copy, modify, and/or distribute this software"]),
                ("Unlicense",   [r"unlicense"])
                ]

# Possible locations of licenses
const LICFILES=["LICENSE", "LICENSE.md", "License.md", "LICENSE.txt", "LICENSE.rst", "UNLICENSE",
                "LICENCE", "LICENCE.md", "Licence.md", "LICENCE.txt", "LICENCE.rst", "UNLICENCE",
                 "README",  "README.md",                "README.txt",
                "COPYING", "COPYING.md",               "COPYING.txt"]

# Special package treatments
# XVFB   = requires X virtual framebuffer
# BINARY = can't run due to a binary dependency that can't be satisfied
# OSX    = only works on OSX
# PYTHON = requires a Python package
const PKGOPTS= ["AppleAccelerate" => :OSX,
                "ApproxFun"     =>  :BINARY,  # seems to need PyPlot, which we also exclude
                "Arduino"       =>  :BINARY,
                "CasaCore"      =>  :BINARY,
                "Clang"         =>  :BINARY,
                "CommonCrawl"   =>  :BINARY,  # needs AWS auth, downloads a lot
                "CoreNLP"       =>  :PYTHON,
                "CPLEX"         =>  :BINARY,
                "CLFFT"         =>  :BINARY,
                "CUDA"          =>  :BINARY,
                "CUDArt"        =>  :BINARY,
                "CUFFT"         =>  :BINARY,
                "DCEMRI"        =>  :PYTHON,
                "ElasticFDA"    =>  :XVFB,  # Seems to use Tk for tests
                "Expect"        =>  :BREAKS,  # Seems to cause a hang
                "Gaston"        =>  :BINARY,  # No Gnuplot on che
                
                "GLAbstraction" =>  :XVFB,
                "GLFW"          =>  :OPENGL,
                "GLPlot"        =>  :OPENGL,
                "GLText"        =>  :OPENGL,
                "GLWindow"      =>  :OPENGL,
                
                "GR"            =>  :BINARY,
                "Gtk"           =>  :XVFB,
                "Gurobi"        =>  :BINARY,
                "Homebrew"      =>  :OSX,
                "IJulia"        =>  :PYTHON,
                "ImageView"     =>  :XVFB,
                "Instruments"   =>  :BINARY,
                "KNITRO"        =>  :BINARY,
                "LevelDB"       =>  :BINARY,
                "LibBSON"       =>  :BINARY,
                "LibGit2"       =>  :BINARY,
                "LibTrading"    =>  :BINARY,
                "Mathematica"   =>  :BINARY,
                "MathProgBase"  =>  :BINARY,
                "MATLAB"        =>  :BINARY,
                "MATLABCluster" =>  :BINARY,
                "Memcache"      =>  :BINARY,
                "ModernGL"      =>  :XVFB,
                "MolecularDynamics" => :BINARY,
                "Mongo"         =>  :BINARY,
                "Mongrel2"      =>  :BINARY,
                "Mosek"         =>  :BINARY,
                "MPI"           =>  :BINARY,
                "Neovim"        =>  :BINARY,
                "NIDAQ"         =>  :BINARY,
                "OpenCL"        =>  :BINARY,
                "OpenGL"        =>  :BINARY,
                "OpenStreetMap" =>  :XVFB,
                "Pandas"        =>  :PYTHON,
                "ProfileView"   =>  :XVFB,
                "PyLexYacc"     =>  :PYTHON,
                "PyPlot"        =>  :XVFB,
                "PySide"        =>  :PYTHON,
                "RdRand"        =>  :BINARY, # Needs latest Intel CPU
                "REPLCompletions" => :DEP,  # Deprecated, just throws error
                "RobotOS"       =>  :BINARY,
                "SDL"           =>  :BINARY,
                "SemidefiniteProgramming" => :BINARY,
                "Sodium"        =>  :BINARY,
                "SymPy"         =>  :PYTHON,
                "Thrift"        =>  :BINARY,
                "Tk"            =>  :XVFB,
                "Twitter"       =>  :BINARY, # need authentication
                "Watcher"       =>  :BINARY, # using it runs forever watching changes etc
                "Winston"       =>  :XVFB,
                "Vega"          =>  :BINARY,
                "VML"           =>  :BINARY,
                "YT"            =>  :PYTHON]
