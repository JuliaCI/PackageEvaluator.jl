#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# This file is a list of constants used in PackageEvaluator, incl.
# - License identification strings
# - Typical names for files where license information can be found
# - A list of packages that need "special treatment" for tests,
#   including whether they need the X virtual framebuffer running
#   and if they can be run at all.

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
# PYTHON = requires a Python package that we haven't got installed
# BREAKS = something about the package doesn't play nice
# OPENGL = Needs OpenGL support, which XVFB can't handle
const PKGOPTS= ["AppleAccelerate" => :OSX,
                "ApproxFun"     =>  :BINARY,    # Seems to need plotting for tests?
                "Arduino"       =>  :BINARY,    # Needs libarduino
                "CasaCore"      =>  :BINARY,    # Needs http://casacore.github.io/casacore/
                "Clang"         =>  :BINARY,    # Needs libclang
                "CommonCrawl"   =>  :BREAKS,    # Needs AWS auth & downloads a lot
                "CoreNLP"       =>  :PYTHON,    # Needs CoreNLP via corenlp-python
                "CPLEX"         =>  :BINARY,    # Commercial software
                "CLFFT"         =>  :BINARY,    # OpenCL
                "CUBLAS"        =>  :BINARY,    # NVIDIA CUDA
                "CUDA"          =>  :BINARY,    # NVIDIA CUDA
                "CUDNN"         =>  :BINARY,    # NVIDIA CUDA
                "CUDArt"        =>  :BINARY,    # NVIDIA CUDA
                "CUFFT"         =>  :BINARY,    # NVIDIA CUDA
                "CURAND"        =>  :BINARY,    # NVIDIA CUDA
                "CUSOLVER"      =>  :BINARY,    # NVIDIA CUDA
                "CUSPARSE"      =>  :BINARY,    # NVIDIA CUDA
                "Expect"        =>  :BREAKS,    # Used to cause hangs
                "GLAbstraction" =>  :OPENGL,
                "GLFW"          =>  :OPENGL,
                "GLPlot"        =>  :OPENGL,
                "GLText"        =>  :OPENGL,
                "GLWindow"      =>  :OPENGL,
                "GLVisualize"   =>  :OPENGL,
                "GR"            =>  :XVFB,      # Plotting package
                "Gtk"           =>  :XVFB,      # GUI package
                "Gurobi"        =>  :BINARY,    # Commercial software
                "Homebrew"      =>  :OSX,
                "IJulia"        =>  :PYTHON,    # Could be interesting to revist
                "ImageView"     =>  :XVFB,      # GUI via Tk.jl
                "Instruments"   =>  :BINARY,    # Needs NI-VISA
                "KNITRO"        =>  :BINARY,    # Commercial software
                "LibTrading"    =>  :BINARY,    # Needs libtrading
                "Mathematica"   =>  :BINARY,    # Commercial software
                "MATLAB"        =>  :BINARY,    # Commercial software
                "MATLABCluster" =>  :BINARY,    # Commercial software
                "Memcache"      =>  :BINARY,    # Needs memcache
                "ModernGL"      =>  :OPENGL,
                "MolecularDynamics" => :BINARY, # Needs xdrfile
                "Mongo"         =>  :BINARY,    # Needs mongo C library
                "Mongrel2"      =>  :BINARY,    # Needs... something
                "Mosek"         =>  :BINARY,    # Commercial software
                "MPI"           =>  :BINARY,    # Needs MPI install and config
                "Neovim"        =>  :BINARY,    # Needs Neovim installed
                "NIDAQ"         =>  :BINARY,    # Needs NIDAQmx
                "OpenCL"        =>  :BINARY,
                "OpenGL"        =>  :BINARY,
                "OpenStreetMap" =>  :XVFB,      # Graphics via Winston
                "Pandas"        =>  :PYTHON,    # Needs pandas
                "Pardiso"       =>  :BINARY,    # Commercial software
                "Polyglot"      =>  :BINARY,    # Froze PkgEval https://github.com/wavexx/Polyglot.jl/issues/1
                "ProfileView"   =>  :XVFB,
                "PyLexYacc"     =>  :PYTHON,    # Needs PLY and attrdict
                "PyPlot"        =>  :XVFB,      # GUI
                "PySide"        =>  :PYTHON,    # Needs PySide/Qt
                "RdRand"        =>  :BINARY,    # Needs latest Intel CPU
                "REPLCompletions" => :DEP,      # Deprecated, just throws error (???)
                "RobotOS"       =>  :PYTHON,    # Needs rospy
                "RudeOil"       =>  :BINARY,    # Needs Docker
                "SemidefiniteProgramming" => :BINARY,   # Needs CSDP
                "Snappy"        =>  :BINARY,    # Needs libsnappy
                "Sodium"        =>  :BINARY,    # Needs libsodium
                "SystemImageBuilder" => :BREAKS,  # Freezes PkgEval
                "ThingSpeak"    =>  :BREAKS,    # Needs API key
                "Thrift"        =>  :BINARY,    # Needs Thrift compiler
                "Tk"            =>  :XVFB,      # GUI package
                "Twitter"       =>  :BREAKS,    # Needs authentication
                "Watcher"       =>  :BREAKS,    # Seems to cause hangs
                "WCSLIB"        =>  :BREAKS,    # Very unreliable download
                "Winston"       =>  :XVFB,      # GUI via Tk.jl
                "VML"           =>  :BINARY,    # Needs MKL
                "YT"            =>  :PYTHON]    # Needs yt
