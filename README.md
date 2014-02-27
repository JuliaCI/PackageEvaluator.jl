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

## What does PackageEvaluator look for (and where)

### Tests

Probably the most important thing is identifying and running your tests. The preferred choice is a single "master test file" that will run all the tests. Heres how it does it:

 * Look for ``runtests.jl``, ``run_tests.jl``, ``tests.jl``,``test.jl``, or ``$PKGNAME.jl`` in...
 * Either the "root" of the package, or in a ``test`` or ``tests`` subfolder.

The search stops once one is found, so if multiple files match these rules then you might be in trouble. Check the code for the specific order if its a problem for you, and file an issue to discuss it.

In the event none of those files exist, we look for a ``test`` or ``tests`` folder. If one of those exists, and has ONE AND ONLY ONE ``.jl`` file in it, that will be treated as the test for the package. A reasonable question is: why not run all the files in the ``test`` folder? The answer is that I'd rather report that I couldn't run the tests at all than erroneously report that the tests fail because they weren't run in the right way.


### License

Licenses are searched for in the following files, in this order (stop once its found):

* ``LICENSE, LICENSE.md, License.md, LICENSE.txt``
* ``LICENCE, LICENCE.md, Licence.md``
* ``README, README.md, README.txt``
* ``COPYING, COPYING.md, COPYING.txt``

We currently support the following licenses - if you don't see your license, or you do but it isn't detected, please file an issue:

* MIT, GPLv2 and v3, LPGLv2.1 and v3, BSD, GNU Affero, Romantic WTF

### Common problems

I've seen quite a few packages fail tests/miss licenses due to having perfectly working masters, but not tagging a new version in METADATA for a long time, so make sure that you are up-to-date there. Additionally make sure that if you report you support 0.2, you actually do!
