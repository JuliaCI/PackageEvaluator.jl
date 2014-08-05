PackageEvaluator.jl
===================

A package + extras that attempt to evaluate the state of individual packages as well as the status of the wider package ecosystem for [Julia](http://julialang.org). Check the status of packages at the [package listing](http://pkg.julialang.org/).

**Exceptions** for packages that can't/shouldn't be tested are in `src/constants.jl`. Open issue/file a PR if you want to add/remove a package.

**Licenses** are searched for in the files listed in `src/constants.jl` and support a variety of licenses. If your license isn't detected, please file an issue.

**Tests** are heuristically identified. The preferred choice is a single "master test file" that will run all the tests. Here is the heuristic:

 * Look for ``runtests.jl``, ``run_tests.jl``, ``tests.jl``,``test.jl``, or ``$PKGNAME.jl`` in...
 * ... either the root of the package, or in a ``test`` or ``tests`` subfolder.
 * If that fails, look for a ``test`` or ``tests`` folder. If one exists, and has one and only one ``.jl`` file in it, use that.

The "best version" is `test/runtests.jl`, and is called by `Pkg.test` as of Julia 0.3.

### More information

PackageEvaluator, as a module, exports three functions:

* `evalPkg(pkg, addremove=true)` - runs various tests on the package `pkg`, adding it first and removing it afterwards by default. Will return a dictionary of test results.
* `featuresToJSON(pkg_name, features)` - return test results as a JSON string, given the dictionary produced by `evalPkg`.
* `testAllPkgs(limit=Inf)` generates a JSON file for every package.

Also, in `extra`, `runandlog.sh` runs the package evaluator in a seperate .julia, saves results.