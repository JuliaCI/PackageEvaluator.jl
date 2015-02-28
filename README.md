PackageEvaluator
================

**The package**: a [Julia](http://julialang.org) package exporting the function `eval_pkg` that gathers some basic information about a package and attempts to run its tests (or the next best thing), then spits the results to a JSON.

**The service**: a [Vagrant](https://www.vagrantup.com/) configuration and some scripts set up to evaluate all Julia packages on stable and nightly versions of Julia, for use on the [Julia package listing](http://pkg.julialang.org/).

## The Service

Are you a package developer who is trying to understand your test results or information as listed on the package website? Then read on:

**Tests** are heuristically identified. The preferred choice is a single "master test file" that will run all the tests. Here is the heuristic:

 1. Look for `runtests.jl`, `run_tests.jl`, `tests.jl`, `test.jl`, or `$PKGNAME.jl` in...
 2. ... `test`` or ``tests` subfolder, or in the the root of the package. If that fails...
 3. ... look for a ``test`` or ``tests`` folder. If one exists, and has one and only one ``.jl`` file in it, use that.

The best case scenario is that `test/runtests.jl` exists, and then PackageEvaluator we use `Pkg.test` which ensures your testing dependencies will be installed too. Anything else is done on a best-effort basis.

**Exceptions** for packages that can't/shouldn't be tested are in `src/constants.jl`. PackageEvaluator runs in an Ubuntu virtual machine, and binary dependencies can be installed manually. Open issue/file a PR if you want to add/remove a package, or want to ask about a dependency.

**Licenses** are searched for in the files listed in `src/constants.jl`. The goal is to support a variety of licenses. If your license isn't detected, please file a pull request.


## The Package

`PackageEvaluator`, as a module, exports one function: `eval_pkg`. It is well documented in `src/PackageEvaluator.jl`.