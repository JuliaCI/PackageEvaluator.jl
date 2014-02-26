PackageEvaluator.jl
===================

A package + extras that attempt to evaluate the state of individual packages as well as the status of the wider package ecosystem for [Julia](http://julialang.org).

## The module

PackageEvaluator, as a module, exports the following functions:

* `evalPkg(pkg, addremove=true)` - runs various tests on the package `pkg`, adding it first and removing it afterwards by default. Will return a dictionary of test results. Defined in PackageEvaluator.jl
* `featuresToJSON(pkg_name, features)` - return test results as a JSON string, given the dictionary produced by `evalPkg`.
* `getDetailsString(pkg_name, features)` - builds a human-readable string that summarizes the testing part of the results dictionary (i.e. `TEST_EXIST, TEST_STATUS, TEST_MASTERFILE`)
* `scorePkg(features, pkg_name, pkg_path, metadata_path, o = STDOUT)` - takes a dictionary of test results produced using `evalPkg`, and pretty-prints a summary to STDOUT (by default) (somewhat deprecated).

## The extras

* `genresults.jl` which can be used to make a standalone package test result listing, and/or a JSON file for every package. Expects two command line arguments: number of packages to test (-1 for all) and a string, either J, H, or JH (J=JSON, H=HTML).
* `runandlog.sh` runs the package evaluator in a seperate .julia, logs results, and then submits them all to status.julialang.org using...
* `postresults.jl`