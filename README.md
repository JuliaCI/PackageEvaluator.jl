PackageEvaluator
================

**The package**: a [Julia](http://julialang.org) package exporting the function `eval_pkg` that gathers some basic information about a package and attempts to run its tests (or the next best thing), then spits the results to a JSON.

**The script**: a [Vagrant](https://www.vagrantup.com/) configuration and provisioning script that are set up to evaluate all Julia packages on stable and nightly versions of Julia, for use on the [Julia package listing](http://pkg.julialang.org/).

## "My package is failing tests! Why is it doing that?"

Possible reasons include:

* **Your package is out of date**. PackageEvaluator tests the last released version of your package, not `master`. Make sure you've tagged a version with your bug fixes included.
* **You have a binary dependency that BinDeps can't handle**.
  * If the binary dependency is a commerical package, or does not work on Ubuntu (e.g. OSX only), then the package should be excluded from testing. Please submit a pull request adding a line to [`src/constants.jl`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/src/constants.jl).
  * If the binary dependency is something that is not installable (or shouldn't be installed) through BinDeps, like a Python package or R package, then it should be added to the provisioning script. Please submit a pull request adding a line to [`scripts/setup.sh`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/scripts/setup.sh).
* **You have a testing-only dependency that you haven't declared**. Create (or check) your package's `test/REQUIRE` file.
* **Your package only works on Windows/OSX/one particular *-nix**. Your package might need to be excluded from testing. Please submit a pull request adding a line to [`src/constants.jl`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/src/constants.jl) saying your package shouldn't be run.
* **Your testing process relies on random numbers**. Please make sure you set a seed or use appropriate tolerances if you rely on random numbers in your tests.
* **Your package relies on X running**. It may be possible to get your package working through the magic of `xvfb`. Please submit a pull request adding a line to [`src/constants.jl`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/src/constants.jl) that specifies that your package needs to be run with `xvfb` active.
* **Your package's tests or installation take too long**. There is a time limit of 10 minutes for installation, and a seperate 10 minute time limit for testing. You can either reduce your testing time, or exclude your package from testing.
* **Your tests aren't being found / wrong test file is being run**. TThe preferred option is that `test/runtests.jl` exists, and then PackageEvaluator will use `Pkg.test`. Some older packages don't implement this, so files are heuristically identified. See [`src/package.jl`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/src/package.jl) for the logic used, or preferably just update your package.
* **Something else**. You'll probably need to check manually on the testing VM. See next section.

(**Licenses** are searched for in the files listed in [`src/constants.jl`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/src/constants.jl). The goal is to support a variety of licenses. If your license isn't detected, please file a pull request with detection logic.)

## Using Vagrant and PackageEvaluator

* [Vagrant](https://www.vagrantup.com/) is a tool for creating and managing virtual machines.
* The configuration of the virtual machine, including the operating system use, live in the [`Vagrantfile`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/scripts/Vagrantfile).
* When the virtual machine(s) are launched with `vagrant up`, a *provisioning script* called [`setup.sh`](https://github.com/IainNZ/PackageEvaluator.jl/blob/master/scripts/setup.sh) is run.
* This script takes two arguments: the first is the version of Julia to use, and the second is the subset of packages to run.
* The arguments are determined by the configurations in the `Vagrantfile`. In particular:
 * `releasesetup` and `releasenightly` just set up the machine with Julia and the same dependencies that PackageEvaluator uses. **Use, e.g. `vagrant up releasesetup; vagrant ssh releasesetup` to debug why a pacakge is failing.**
 * `release` and `nightly` do the setup and evaluate all the packages.
 * `releaseAL`, `releaseMZ`, `nightlyAL`, `nightlyMZ` evaluate only packages with names beginning with those letters.
* PackageEvaluator runs all the last four configurations in parallel, using `runvagrant.sh`.
