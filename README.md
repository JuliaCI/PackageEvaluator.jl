PackageEvaluator.jl
===================

A tool to evaluate the quality of a Julia pacakge.

Tied into the work on [Julep 2](https://gist.github.com/IainNZ/6086173) on improving the quality of the Julia package ecosystem.

The code is organized as a module, that exports the following functions:

* `evalPkg(pkg, addremove=true)` - runs various tests on the package `pkg`, adding it first and removing it afterwards by default. Will return a dictionary of test results. Defined in PackageEvaluator.jl
* `scorePkg(features, pkg_name, pkg_path, metadata_path, o = STDOUT)` - takes a dictionary of test results produced using `evalPkg`, and pretty-prints a summary to STDOUT (by default).
* `featuresToJSON(pkg_name, features)` - return test results as a JSON string.
* `getDetailsString(pkg_name, features)` - builds a human-readable string that summarizes the testing results (`TEST_EXIST, TEST_STATUS, TEST_MASTERFILE`)

Extras contains two things of note:

* `genresults.jl` which can be used to make a standalone package test result listing, and/or a JSON file for every package.