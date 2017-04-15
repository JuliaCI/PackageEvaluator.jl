#######################################################################
# PackageEvaluator
# https://github.com/JuliaCI/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# See description in scripts/setup.sh for the purpose of this file
#######################################################################

include("constants.jl")

function prepare_test()
    pkg_name = ARGS[1]
    pkg_path = Pkg.dir(pkg_name)

    # Are tests even meaningful?
    if (pkg_name in keys(PKGOPTS)) && PKGOPTS[pkg_name] != :XVFB
        # They can't be run for some reason
        print_with_color(:yellow, "PKGEVAL: Cannot run tests, code: $(PKGOPTS[pkg_name])\n")
        exit(255)
    end

    # Check for the existence of `test/runtests.jl` file. If it has it,
    # we can use Pkg.test to test it. Otherwise we will settle for trying
    # to just load the package.
    if !isfile(joinpath(pkg_path,"test","runtests.jl"))
        # Doesn't exist!
        print_with_color(:yellow, "PKGEVAL: Package cannot be tested with Pkg.test\n")
        exit(254)
    end

    # Tests exist, so lets create a shell script to run them
    fp = open(string(pkg_name,".sh"),"w")
    println(fp, "set -o pipefail")  # So tee doesn't swallow the exit code

    if is_apple()
        # Force usage of coreutils' timeout
        print(fp, "gtimeout -s9 $(TEST_TIMEOUT)s ")
    elseif is_linux()
        # Separate PID namespace to prevent any child process to escape
        # the timeout invocation and lock our tests
        print(fp, "sudo -E timeout -s9 $(TEST_TIMEOUT)s unshare -fp runuser -u \$USER -- ")
    else
        print(fp, "timeout -s9 $(TEST_TIMEOUT)s ")
    end

    if get(PKGOPTS, pkg_name, :NORMAL) == :XVFB
        print(fp, "xvfb-run ")
    end
    print(fp, "julia -e 'versioninfo(true); Pkg.test(\"", pkg_name, "\")'")
    print(fp, " 2>&1 | tee PKGEVAL_", pkg_name, "_test.log")
    close(fp)
end

prepare_test()
