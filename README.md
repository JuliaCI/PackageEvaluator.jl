PackageEvaluator
================

[![Build Status](https://travis-ci.org/JuliaCI/PackageEvaluator.jl.svg?branch=master)](https://travis-ci.org/JuliaCI/PackageEvaluator.jl)

The purpose of PackageEvaluator is to attempt to test every Julia package nightly, and to provide the information required to generate the [Julia package listing](http://pkg.julialang.org/).

This is currently done for Julia 0.5, 0.6, and nightly, and the tests are run in Ubuntu 14.04 LTS ("Trusty Tahr") virtual machines managed with [Vagrant](https://www.vagrantup.com/). This allows users to debug why their tests are failing, and allows PackageEvaluator to be run almost anywhere.

The code itself, in particular `scripts/setup.sh`, is heavily commented, so check that out for more information.

## "My package is failing tests!"

Possible reasons include:

* **Your package is out of date**. PackageEvaluator tests the last released version of your package, not `master`. Make sure you've tagged a version with your bug fixes included.
* **You have a binary dependency that BinDeps can't handle**.
  * If the binary dependency is a commerical package, or does not work on Ubuntu (e.g. OSX only), then the package should be excluded from testing. Please submit a pull request adding a line to [`src/constants.jl`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/src/constants.jl).
  * If the binary dependency is something that is not installable (or shouldn't be installed) through BinDeps, like a Python package or R package, then it should be added to the provisioning script. Please submit a pull request adding a line to [`scripts/setup.sh`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/scripts/setup.sh).
* **You have a testing-only dependency that you haven't declared**. Create (or check) your package's `test/REQUIRE` file.
* **Your package only works on Windows/OSX/one particular *-nix**. Your package might need to be excluded from testing. Please submit a pull request adding a line to [`src/constants.jl`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/src/constants.jl) saying your package shouldn't be run.
* **Your testing process relies on random numbers**. Please make sure you set a seed or use appropriate tolerances if you rely on random numbers in your tests.
* **Your package relies on X running**. It may be possible to get your package working through the magic of `xvfb`. Please submit a pull request adding a line to [`src/constants.jl`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/src/constants.jl) that specifies that your package needs to be run with `xvfb` active.
* **Your package's tests or installation take too long**. There is a time limit of 30 minutes for installation, and a seperate 10 minute time limit for testing. You can either reduce your testing time, or exclude your package from testing.
* **Your package requires too much memory**. The VMs only have 2 GB of RAM. You can either reduce your test memory usage, or exclude your package from testing.
* **Your tests aren't being found / wrong test file is being run**. Your package needs a `test/runtests.jl` file. PackageEvaluator will execute it with `Pkg.test`.
* **Something else**. You'll probably need to check manually on the testing VM. See next section.

(**Licenses** are searched for in the files listed in [`src/constants.jl`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/src/constants.jl). The goal is to support a variety of licenses. If your license isn't detected, please file a pull request with detection logic.)

## Using Vagrant and PackageEvaluator

* [Vagrant](https://www.vagrantup.com/) is a tool for creating and managing virtual machines.
* The configuration of the virtual machine, including the operating system to use, live in the [`Vagrantfile`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/scripts/Vagrantfile).
* When the virtual machine(s) are launched with `vagrant up`, a *provisioning script* called [`setup.sh`](https://github.com/JuliaCI/PackageEvaluator.jl/blob/master/scripts/setup.sh) is run.
* This script takes two arguments. The first is the version of Julia
  to use (`0.5` or `0.6` or `0.7`)
* The second determines the mode to operate in:
    * `setup`: set up the machine with Julia and the same
      dependencies that are used for a full PackageEvaluator run, but
      do not do any testing.
    * `all`: do `setup` and evaluate all the packages.
    * `AK` or `LZ`: evaluate only packages with names beginning with those letters.
* Each combination of settings corresponds to a named virtual machine - see `scripts/Vagrantfile` for the list of the VMs.
