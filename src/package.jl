#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################

# On Linux systems there is a timeout program available (or one that
# can be installed easily). OSX doesn't come with one, but we can do
# brew install coreutils
# to get it (albeit with a different name)
const TIMEOUTPATH = @osx? "gtimeout" : "timeout"

# General info, including the Git version, date of last commit in 
# the tagged version.
function getInfo(features, pkg, pkg_path)
    url_path = joinpath(Pkg.dir(),"METADATA",pkg,"url")
    url      = chomp(readall(url_path))
    url      = (url[1:3] == "git")   ? url[7:(end-4)] :
               (url[1:5] == "https") ? url[9:(end-4)] : ""
    features[:URL]     = string("http://", url)

    cur_dir  = pwd()
    cd(pkg_path)

    features[:GITSHA]  = ""
    features[:GITDATE] = ""
    try
        # gitlog = "08ab40...c96c40 2014-05-22 17:17:40 -0400"
        gitlog  = readall(`git log -1 --format="%H %ci"`)
        spl     = split(gitlog, " ")
        features[:GITSHA]  = spl[1]
        features[:GITDATE] = string(spl[2]," ",spl[3]," ",spl[4])
    catch
        # Just leave blank
    end

    cd(cur_dir)
end


#######################################################################
# License file
function checkLicense(features, pkg_path)
    features[:LICENSE_EXISTS] = false
    features[:LICENSE]        = "Unknown"
    features[:LICENSE_FILE]   = ""

    # Test for some sort of license file existense
    for filename in LICFILES
        fullfilename = joinpath(pkg_path, filename)
        if isfile(fullfilename)
            # If it isn't just a README, then its probably a license file
            # of some sort. At least we found something if not the license
            # itself.
            if !contains(filename, "README")
                features[:LICENSE_FILE] = filename
            end
            if guessLicense(features, fullfilename)
                # Stop once we identify a license 
                # Make sure to set license file again, in case of README...
                features[:LICENSE_FILE] = filename
                return
            end
        end
    end
end

function guessLicense(features, filename)
    # Be greedy, read the whole file
    text = lowercase(readall(filename))
    
    for license in LICENSES
        for regex in license[2]
            if ismatch(regex, text)
                features[:LICENSE_EXISTS] = true
                features[:LICENSE] = license[1]
                return true
            end
        end
    end

    return false
end


#######################################################################
# Testing folder/files
function checkTesting(features, pkg_path, pkg_name, usetimeout, juliapath, juliapkg)
    # Intialize to defaults
    features[:TEST_MASTERFILE] = ""
    features[:TEST_EXIST]      = false
    features[:TEST_POSSIBLE]   = true
    features[:TEST_STATUS]     = ""
    features[:TEST_USING_LOG]  = "using test not run"
    features[:TEST_FULL_LOG]   = "no tests to run"

    # Look for a master test file. Hopefully this will be test/runtests.jl
    # so we can use Pkg.test. Otherwise we'll have to guess and hope for best
    pkg_dot_test_capable = false
    for root in ["test","tests",""]
        for file in ["runtests", "run_tests", "tests", "test", pkg_name]
            filename = joinpath(pkg_path,root,file)*".jl"
            !isfile(filename) && continue
            features[:TEST_MASTERFILE] = filename
            features[:TEST_EXIST] = true
            pkg_dot_test_capable = (file == "runtests" && root == "test")
            break
        end
    end
    features[:TEST_EXIST] && !pkg_dot_test_capable &&
        print_with_color(:yellow, """PKGEVAL: Found a master test file:
                                              $(features[:TEST_MASTERFILE])\n""")
    pkg_dot_test_capable &&
        print_with_color(:yellow, "PKGEVAL: Package can be tested with Pkg.test\n")

    # If we can't find any master files, look to see if they have
    # a single "obvious" test file that we can try to run.
    if !features[:TEST_EXIST]
        for test_folder in ["test", "tests"]
            dir = joinpath(pkg_path, test_folder)
            !isdir(dir) && continue
            jl_files  = filter(x->contains(x,".jl"), readdir(dir))
            features[:TEST_EXIST] = (length(jl_files) > 0)
            if length(jl_files) == 1
                # Only one test file, yay
                features[:TEST_MASTERFILE] = joinpath(pkg_path, test_folder, jl_files[1])
            end
            break
        end
        features[:TEST_MASTERFILE] != "" &&
        print_with_color(:yellow, """PKGEVAL: Unsure about test file, guessed:
                                              $(features[:TEST_MASTERFILE])\n""")
    end


    # Are tests even meaningful?
    if pkg_name in keys(PKGOPTS) && PKGOPTS[pkg_name] != :XVFB
        # They can't be run for some reason
        print_with_color(:yellow, "PKGEVAL: Cannot run tests, code: $(PKGOPTS[pkg_name])\n")
        features[:TEST_POSSIBLE] = false
        features[:TEST_STATUS]   = "not_possible"
        return
    end
  
    
    # Not excluded. See if "using" works
    # Create a simple test file
    using_path = "PKGEVAL_$(pkg_name)_using.jl"
    fp = open(using_path,"w")
    write(fp, "versioninfo()\n")
    if juliapkg != nothing
        write(fp, "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\"\n")
        write(fp, "println(Pkg.dir(\"$pkg_name\"))\n")
    end
    # Hack: JLDArchives doesn't have a src/ folder - but does have useful tests to
    # be run by PkgEval. So we'll do-nothing for that package and any others like
    # it by checking if their src/ folder exists
    if isdir(joinpath(pkg_path,"src"))
        write(fp, "using $pkg_name\n")
        write(fp, "println(\"=*=PKGEVAL=*=\")\n")
        write(fp, "map(x->println(\"$(pkg_name).\",x), names($(pkg_name)))")
    end
    close(fp)
    # Create a file to hold output
    log_name = "PKGEVAL_$(pkg_name)_using.log"
    log, ok = "", true
    print_with_color(:yellow, "PKGEVAL: Trying to load package with `using`\n")
    if get(PKGOPTS, pkg_name, :NORMAL) == :XVFB
        if usetimeout
            log, ok = run_cap_all(`xvfb-run $TIMEOUTPATH 300s $juliapath $using_path`,log_name)
        else
            log, ok = run_cap_all(                  `xvfb-run $juliapath $using_path`,log_name)
        end
    else
        if usetimeout
            log, ok = run_cap_all(         `$TIMEOUTPATH 300s $juliapath $using_path`,log_name)
        else
            log, ok = run_cap_all(                           `$juliapath $using_path`,log_name)
        end
    end
    features[:TEST_USING_LOG] = log
    features[:EXP_NAMES] = {}
    # Check exit code
    if ok
        # Extract exported names
        s = split(log, "=*=PKGEVAL=*=")
        if length(s) == 1
            # Then it didn't appear
            print_with_color(:yellow, "PKGEVAL: No exported names found")
        else
            features[:EXP_NAMES] = filter(x->length(x)>0,map(chomp,split(s[2],"\n")))
            features[:TEST_USING_LOG] = s[1]
            print_with_color(:yellow, "PKGEVAL: Found $(length(features[:EXP_NAMES])) names\n")
        end

        # Check for weird edge case where package has build error
        # but using doesn't fail. This was observed in IJulia first.
        if contains(features[:ADD_LOG], "had build errors")
            features[:TEST_USING_LOG] *= "... but failing due to build errors."
            features[:TEST_STATUS] = "using_fail"
            print_with_color(:yellow, "PKGEVAL: Package seems to have had build errors\n")
            return
        end
        features[:TEST_STATUS] = "using_pass"
        print_with_color(:yellow, "PKGEVAL: Package can be loaded\n")
    else
        # Didn't load without errors, even if it has tests they will fail
        features[:TEST_STATUS] = "using_fail"
        print_with_color(:yellow, "PKGEVAL: Package cannot be loaded\n")
        return
    end

    # No test masterfile to run means there is nothing more we can do
    if features[:TEST_MASTERFILE] == ""
        print_with_color(:yellow, "PKGEVAL: No test script found, so cannot proceed\n")
        return
    end
    
    # Found a master test file, run it to see if it works
    # Change to pkg dir in case tests expect that
    old_dir = pwd()
    cd(splitdir(features[:TEST_MASTERFILE])[1])
    # Create a file to hold output
    log_name = "PKGEVAL_$(pkg_name)_test.log"
    log, ok = "", true
    pkg_test = pkg_dot_test_capable ? "Pkg.test(\"$(pkg_name)\")" :
                                      "include(\"$(features[:TEST_MASTERFILE])\")"
    pkg_test = "ENV[\"JULIA_PKGDIR\"] = \"$(juliapkg)\"; " * pkg_test
    if get(PKGOPTS, pkg_name, :NORMAL) == :XVFB
        print_with_color(:yellow, "PKGEVAL: Running '$(pkg_test)' with framebuffer\n")
        if usetimeout
            log, ok = run_cap_all(`xvfb-run $TIMEOUTPATH 600s $juliapath -e $pkg_test`,log_name)
        else
            log, ok = run_cap_all(                  `xvfb-run $juliapath -e $pkg_test`,log_name)
        end
    else
        print_with_color(:yellow, "PKGEVAL: Running '$(pkg_test)'\n")
        if usetimeout
            log, ok = run_cap_all(         `$TIMEOUTPATH 600s $juliapath -e $pkg_test`,log_name)
        else
            log, ok = run_cap_all(                           `$juliapath -e $pkg_test`,log_name)
        end
    end
    features[:TEST_FULL_LOG] = log
    # Check exit code
    if ok
        features[:TEST_STATUS] = "full_pass"
        print_with_color(:yellow, "PKGEVAL: Test pass!\n")
    else
        # Has tests, and they failed
        features[:TEST_STATUS] = "full_fail"
        if contains(features[:TEST_FULL_LOG], "[124]")
            features[:TEST_FULL_LOG] *= "FAILED DUE TO TIMEOUT"
            print_with_color(:yellow, "PKGEVAL: Test timeout!\n")
        else
            print_with_color(:yellow, "PKGEVAL: Test failed!\n")
        end
    end
    cd(old_dir)
end