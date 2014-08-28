#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################

# General info, including the Git version, date of last commit in 
# the tagged version.
function getInfo(features, pkg_path)
    features[:GITSHA]  = ""
    features[:GITDATE] = ""
    try
        # gitlog = "08ab40...c96c40 2014-05-22 17:17:40 -0400"
        gitlog  = readall(`git log -1 --format="%H %ci"`)
        spl     = split(gitlog, " ")
        features[:GITSHA]  = spl[1]
        features[:GITDATE] = string(spl[2]," ",spl[3]," ",spl[4])
    catch
        # NOP
    end
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
function checkTesting(features, pkg_path, pkg_name, usetimeout)
    # Intialize to defaults
    features[:TEST_MASTERFILE] = ""
    features[:TEST_EXIST]      = false
    features[:TEST_POSSIBLE]   = true
    features[:TEST_STATUS]     = ""
    features[:TEST_USING_LOG]  = "using test not run"
    features[:TEST_FULL_LOG]   = "no tests to run"

    # Look for a master test file
    pkg_dot_test_capable = false
    for root in ["test","tests",""]
        for file in ["runtests", "run_tests", "tests", "test", pkg_name]
            filename = joinpath(pkg_path,root,file)*".jl"
            !isfile(filename) && continue
            features[:TEST_MASTERFILE] = filename
            features[:TEST_EXIST] = true
            pkg_dot_test_capable = (file == "runtests")
            break
        end
    end

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
    end
  

    # Are tests even meaningful?
    if pkg_name in keys(PKGOPTS) && PKGOPTS[pkg_name] != :XVFB
        # They can't be run for some reason
        features[:TEST_POSSIBLE] = false
        features[:TEST_STATUS]   = "not_possible"
        return
    end
  
    
    # Not excluded. See if "using" works
    # Create a simple test file
    fp = open("testusing.jl","w")
    write(fp, "versioninfo()\n")
    write(fp, "using $pkg_name")
    close(fp)
    # Create a file to hold output
    log_name = "$(pkg_name)_using.log"
    log, ok = "", true
    if get(PKGOPTS, pkg_name, :NORMAL) == :XVFB
        if usetimeout
            log, ok = run_cap_all(`xvfb-run timeout 300s julia testusing.jl`,log_name)
        else
            log, ok = run_cap_all(             `xvfb-run julia testusing.jl`,log_name)
        end
    else
        if usetimeout
            log, ok = run_cap_all(         `timeout 300s julia testusing.jl`,log_name)
        else
            log, ok = run_cap_all(                      `julia testusing.jl`,log_name)
        end
    end
    features[:TEST_USING_LOG] = log
    # Check exit code
    if ok
        # Check for weird edge case where package has build error
        # but using doesn't fail. This was observed in IJulia.
        if contains(features[:ADD_LOG], "had build errors")
            features[:TEST_USING_LOG] *= "... but failing due to build errors."
            features[:TEST_STATUS] = "using_fail"
            return
        end
        features[:TEST_STATUS] = "using_pass"
    else
        # Didn't load without errors, even if it has tests they will fail
        features[:TEST_STATUS] = "using_fail"
        return
    end

    # No test masterfile to run means there is nothing more we can do
    features[:TEST_MASTERFILE] == "" && return
    
    # Found a master test file, run it to see if it works
    # Change to pkg dir in case tests expect that
    old_dir = pwd()
    cd(splitdir(features[:TEST_MASTERFILE])[1])
    # Create a file to hold output
    log_name = "$(pkg_name)_test.log"
    log, ok = "", true
    pkg_test = "Pkg.test(\"$(pkg_name)\")"
    if get(PKGOPTS, pkg_name, :NORMAL) == :XVFB
        if usetimeout
            if pkg_dot_test_capable
                log, ok = run_cap_all(`xvfb-run timeout 300s julia -e $pkg_test`,log_name)
            else
                log, ok = run_cap_all(`xvfb-run timeout 300s julia $(features[:TEST_MASTERFILE])`,log_name)
            end
        else
            if pkg_dot_test_capable
                log, ok = run_cap_all(             `xvfb-run julia -e $pkg_test`,log_name)
            else
                log, ok = run_cap_all(             `xvfb-run julia $(features[:TEST_MASTERFILE])`,log_name)
            end
        end
    else
        if usetimeout
            if pkg_dot_test_capable
                log, ok = run_cap_all(         `timeout 300s julia -e $pkg_test`,log_name)
            else
                log, ok = run_cap_all(         `timeout 300s julia $(features[:TEST_MASTERFILE])`,log_name)
            end
        else
            if pkg_dot_test_capable
                log, ok = run_cap_all(                      `julia -e $pkg_test`,log_name)
            else
                log, ok = run_cap_all(                      `julia $(features[:TEST_MASTERFILE])`,log_name)
            end
        end
    end
    features[:TEST_FULL_LOG] = log
    # Check exit code
    if ok
        features[:TEST_STATUS] = "full_pass"
    else
        # Has tests, and they failed
        features[:TEST_STATUS] = "full_fail"
        if contains(features[:TEST_FULL_LOG], "[124]")
            features[:TEST_FULL_LOG] *= "FAILED DUE TO TIMEOUT"
        end
    end
end
