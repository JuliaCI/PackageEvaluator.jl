###############################################################################
# General info, including the Git version, date of last commit in the tagged
# version, and the Julia version we are testing with right now
function getInfo(features, pkg_path)
    cd(pkg_path)
    gitsha  = ""
    gitdate = ""
    jlsha   = ""
    try
        # gitlog = "08ab40...c96c40 2014-05-22 17:17:40 -0400"
        gitlog  = readall(`git log -1 --format="%H %ci"`)
        spl     = split(gitlog, " ")
        gitsha  = spl[1]
        gitdate = string(spl[2]," ",spl[3]," ",spl[4])
        # Hack for running PkgEval on Julia 0.2
        if VERSION.minor == 2 && VERSION.major == 0
            jlsha = Base.BUILD_INFO.commit
        else
            jlsha = Base.GIT_VERSION_INFO.commit
        end
    catch
        # NOP
    end
    features[:GITSHA]   = gitsha
    features[:GITDATE]  = gitdate
    features[:JLCOMMIT] = jlsha
end


###############################################################################
# License file
function checkLicense(features, pkg_path)

    features[:LICENSE_EXISTS] = false
    features[:LICENSE] = "Unknown"
    features[:LICENSE_FILE] = ""

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
function checkTesting(features, pkg_path, pkg_name)
    # Intialize to pessimistic defaults
    features[:TEST_EXIST] = false
    features[:TEST_MASTERFILE] = ""

    # Look for a master test file
    for root in ["test","tests",""]
        for file in ["runtests", "run_tests", "tests", "test", pkg_name]
            filename = joinpath(pkg_path,root,file)*".jl"
            !isfile(filename) && continue
            features[:TEST_MASTERFILE] = filename
            features[:TEST_EXIST] = true
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


  
  # Do they have a .travis.yml file?
  travis_file = joinpath(pkg_path, ".travis.yml")
  features[:TEST_TRAVIS] = isfile(travis_file)

  features[:TEST_STATUS] = ""

  # Are tests even meaningful?
  features[:TEST_POSSIBLE] = true
  #features[:TEST_POSSIBLE] &= !(pkg_name == "ApproxFun")    # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "Arduino")      # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Clang")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "CPLEX")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "CLFFT")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "CUDA")         # Reason: binaries
  #features[:TEST_POSSIBLE] &= !(pkg_name == "Gaston")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "GLFW")         # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Gtk")          # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Gurobi")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Homebrew")     # Reason: OSX
  #features[:TEST_POSSIBLE] &= !(pkg_name == "ImageView")    # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mathematica")  # Reason: Mathematica
  features[:TEST_POSSIBLE] &= !(pkg_name == "MathProgBase") # Reason: binaries (for now)
  features[:TEST_POSSIBLE] &= !(pkg_name == "MATLAB")       # Reason: MATLAB
  features[:TEST_POSSIBLE] &= !(pkg_name == "MATLABCluster") # Reason: MATLAB
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mongo")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mongrel2")     # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mosek")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "OpenCL")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "OpenGL")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Pandas")       # Reason: python
  #features[:TEST_POSSIBLE] &= !(pkg_name == "ProfileView")  # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "PyLexYacc")    # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "PyPlot")       # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "PySide")       # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "RdRand")       # Reason: needs latest Intel CPU
  features[:TEST_POSSIBLE] &= !(pkg_name == "SemidefiniteProgramming") # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Sodium")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "SymPy")        # Reason: python
  #features[:TEST_POSSIBLE] &= !(pkg_name == "Tk")           # Reason: Tk
  #features[:TEST_POSSIBLE] &= !(pkg_name == "Winston")      # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "Vega")         # Reason: weird build
  features[:TEST_POSSIBLE] &= !(pkg_name == "VML")          # Reason: binaries
  
  if !features[:TEST_POSSIBLE]
    features[:TEST_STATUS] = "not_possible"
    return
  end
  
  # Not excluded. See if "using" works
  testoutput = ""
  try
    fp = open("testusing.jl","w")
    write(fp, "using $pkg_name; println(names($pkg_name))\n")
    close(fp)
    testoutput = readall(`timeout 300s xvfb-run julia testusing.jl`)
    features[:TEST_STATUS] = "using_pass"
    features[:EXP_NAMES] = "" #chomp(testoutput)  disabled
  catch
    # Didn't run without errors, even if it has
    # tests they are 100% guaranteed to fail
    features[:TEST_STATUS] = "using_fail"
    return
  end

  if features[:TEST_MASTERFILE] != ""
    # Found a master test file
    # Run it to see if it works
    # Run the tests to see how they go
    testoutput = ""
    try
      # Move into the package directory in case tests rely on that
      # First saw in ASCIIPlots
      curdir = strip(readall(`pwd`))
      cd(splitdir(features[:TEST_MASTERFILE])[1])
      # Use timeout to handle cases like the GeoIP bug
      testoutput = readall(`timeout 300s julia $(features[:TEST_MASTERFILE])`)
      cd(curdir)
      features[:TEST_STATUS] = "full_pass"
    catch err
      # Has tests, and they failed
      features[:TEST_STATUS] = "full_fail"
      if contains(err.msg, "[124]")
        println("FAILED DUE TO TIMEOUT")
      end
    end
  end

end
