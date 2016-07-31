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
                ("MPL v2",[
                    r"mpl version 2",
                    r"mozilla public license version 2"]),
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
const PKGOPTS = Dict([
    ("AppleAccelerate"        , :OSX),
    ("AWSCore"                , :BINARY),    # Needs credentials (#119)
    ("AWSEC2"                 , :BINARY),    # Needs credentials (#119)
    ("AWSIAM"                 , :BINARY),    # Needs credentials (#119)
    ("AWSLambda"              , :BINARY),    # Needs credentials (#119)
    ("AWSS3"                  , :BINARY),    # Needs credentials (#119)
    ("AWSSNS"                 , :BINARY),    # Needs credentials (#119)
    ("AWSSQS"                 , :BINARY),    # Needs credentials (#119)
    ("CPLEX"                  , :BINARY),    # Commercial software
    ("CLFFT"                  , :BINARY),    # OpenCL
    ("CUBLAS"                 , :BINARY),    # NVIDIA CUDA
    ("CUDA"                   , :BINARY),    # NVIDIA CUDA
    ("CUDAdrv"                , :BINARY),    # NVIDIA CUDA
    ("CUDNN"                  , :BINARY),    # NVIDIA CUDA
    ("CUDArt"                 , :BINARY),    # NVIDIA CUDA
    ("CUFFT"                  , :BINARY),    # NVIDIA CUDA
    ("CURAND"                 , :BINARY),    # NVIDIA CUDA
    ("CUSOLVER"               , :BINARY),    # NVIDIA CUDA
    ("CUSPARSE"               , :BINARY),    # NVIDIA CUDA
    ("EEG"                    , :XVFB),      # GUI via Tk.jl
    ("GLAbstraction"          , :OPENGL),
    ("GLFW"                   , :OPENGL),
    ("GLPlot"                 , :OPENGL),
    ("GLText"                 , :OPENGL),
    ("GLWindow"               , :OPENGL),
    ("GLVisualize"            , :OPENGL),
    ("GR"                     , :XVFB),      # Plotting package
    ("Gtk"                    , :XVFB),      # GUI package
    ("Gurobi"                 , :BINARY),    # Commercial software
    ("Homebrew"               , :OSX),
    ("ImageView"              , :XVFB),      # GUI via Tk.jl
    ("InspectDR"              , :XVFB),      # Plotting package
    ("KNITRO"                 , :BINARY),    # Commercial software
    ("Mathematica"            , :BINARY),    # Commercial software
    ("MATLAB"                 , :BINARY),    # Commercial software
    ("MATLABCluster"          , :BINARY),    # Commercial software
    ("ModernGL"               , :OPENGL),
    ("OpenCL"                 , :BINARY),
    ("OpenGL"                 , :BINARY),
    ("OpenStreetMap"          , :XVFB),      # Graphics via Winston
    ("Pardiso"                , :BINARY),    # Commercial software
    ("ProfileView"            , :XVFB),
    ("PyPlot"                 , :XVFB),      # GUI
    ("QuartzImageIO"          , :OSX),
    ("Rsvg"                   , :XVFB),      # Needs Gtk -> X11
    ("Tk"                     , :XVFB),      # GUI package
    ("Winston"                , :XVFB),      # GUI via Tk.jl
])
