###############################################################################
# General info, including the Git version, date of last commit in the tagged
# version, and the Julia version we are testing with right now
function getInfo(features, pkg_path)
  cd(pkg_path)
  gitsha = ""
  gitdate = ""
  jlsha = ""
  try
    gitlog = readall(`git log -1 --format="%H %ci"`)
    spl = split(gitlog, " ")
    gitsha = spl[1]
    gitdate = string(spl[2]," ",spl[3]," ",spl[4])
    if VERSION.minor == 2 && VERSION.major == 0
        jlsha = Base.BUILD_INFO.commit
    else
        jlsha = Base.GIT_VERSION_INFO.commit
    end
  catch
    # NOP
  end
  features[:GITSHA] = gitsha
  features[:GITDATE] = gitdate
  features[:JLCOMMIT] = jlsha
end

###############################################################################
# REQUIRE file (the one in the root directory of the package itself)
function checkREQUIRE(features, pkg_path)
  REQUIRE_path = joinpath(pkg_path, "REQUIRE")
  if isfile(REQUIRE_path)
    # Exists
    features[:REQUIRE_EXISTS] = true
    # Does it specifiy a Julia dependency?
    grep_result = readall(REQUIRE_path)
    features[:REQUIRE_VERSION] = ismatch(r"julia", grep_result)
  else
    # Does not exist
    features[:REQUIRE_EXISTS] = false
    features[:REQUIRE_VERSION] = false
  end
end

###############################################################################
# License file
function checkLicense(features, pkg_path)

  features[:LICENSE_EXISTS] = false
  features[:LICENSE] = "Unknown"
  features[:LICENSE_FILE] = ""

  # Test for some sort of license file first
  possible_files = ["LICENSE",
                    "LICENSE.md",
                    "License.md",
                    "LICENCE",
                    "LICENCE.md",
                    "Licence.md",
                    "LICENSE.txt",
                    "README",
                    "README.md",
                    "README.txt",
                    "COPYING",
                    "COPYING.md",
                    "COPYING.txt"]
  for filename in possible_files
    fullfilename = joinpath(pkg_path, filename)
    if isfile(fullfilename)
      # If it isn't a README, then its probably a license file of some sort
      # So at least we found a FILE if not the license
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

  # MIT License
  if ismatch(r"mit license", text) ||
     ismatch(r"mit expat license", text) ||
     ismatch(r"mit \"expat\" license", text) ||
     ismatch(r"permission is hereby granted, free of charge,", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "MIT"
  # GPL v2
  elseif ismatch(r"gpl version 2", text) ||
         ismatch(r"gnu general public license\s+version 2", text) ||
         ismatch(r"gnu general public license, version 2", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v2"
  # GPL v3
  elseif ismatch(r"gpl version 3", text) ||
         ismatch(r"http://www.gnu.org/licenses/gpl-3.0.txt", text) ||
         ismatch(r"gnu general public license\s+version 3", text) ||
         ismatch(r"gpl v3", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v3"
  # LGPL v2.1
  elseif ismatch(r"lgpl version 2.1", text) ||
         ismatch(r"gnu lesser general public license\s+version 2\.1", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "LGPL v2.1"
  # LGPL v3.0
  elseif ismatch(r"lgpl-3.0", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "LGPL v3.0"
  # BSD
  elseif ismatch(r"bsd", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "BSD"
  # GNU Affero
  elseif ismatch(r"gnu affero general public license", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GNU Affero"
  # Romantic WTF public license (!!) (see TOML.jl)
  elseif ismatch(r"romantic wtf public license", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "Romantic WTF"
  # No license identified
  else
    return false
  end

  return true
end


###############################################################################
# Testing folder/files
function checkTesting(features, pkg_path, pkg_name)
  features[:TEST_EXIST] = false

  # Look for a master test file
  possible_files = [
    joinpath(pkg_path, "test",  "runtests.jl"),
    joinpath(pkg_path, "tests", "runtests.jl"),
    joinpath(pkg_path,          "runtests.jl"),
    joinpath(pkg_path, "test",  "run_tests.jl"),
    joinpath(pkg_path, "tests", "run_tests.jl"),
    joinpath(pkg_path,          "run_tests.jl"),
    joinpath(pkg_path, "test",  "tests.jl"),
    joinpath(pkg_path, "tests", "tests.jl"),
    joinpath(pkg_path,          "tests.jl"),
    joinpath(pkg_path, "test",  "test.jl" ),
    joinpath(pkg_path, "tests", "test.jl" ),
    joinpath(pkg_path,          "test.jl" ),
    joinpath(pkg_path, "test",  "$(pkg_name).jl"),
    joinpath(pkg_path, "tests", "$(pkg_name).jl")]
  features[:TEST_MASTERFILE] = ""
  for filename in possible_files
    if isfile(filename)
      features[:TEST_MASTERFILE] = filename
      features[:TEST_EXIST] = true
      break
    end
  end

  # If we can't find any master files, look to see if they have
  # a single "obvious" test file.
    if !features[:TEST_EXIST]
        for test_folder in ["test", "tests"]
            try
                test_files = readdir(joinpath(pkg_path, test_folder))
                jl_files = String[]
                for file in test_files
                    if contains(file, ".jl")
                        push!(jl_files, file)
                    end
                end
                if length(jl_files) > 0
                    features[:TEST_EXIST] = true
                end
                if length(jl_files) == 1
                    # Only one test file, yay
                    features[:TEST_MASTERFILE] = joinpath(pkg_path, test_folder, jl_files[1]) 
                end
                break
            catch
                #println("Error on ", test_folder)
            end
        end
    end


  
  # Do they have a .travis.yml file?
  travis_file = joinpath(pkg_path, ".travis.yml")
  features[:TEST_TRAVIS] = isfile(travis_file)

  features[:TEST_STATUS] = ""

  # Are tests even meaningful?
  features[:TEST_POSSIBLE] = true
  features[:TEST_POSSIBLE] &= !(pkg_name == "Arduino")      # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Clang")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "CPLEX")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "CLFFT")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "CUDA")         # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "FITSIO")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Gaston")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Gtk")          # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Gurobi")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "ImageView")    # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "MathProgBase") # Reason: binaries (for now)
  features[:TEST_POSSIBLE] &= !(pkg_name == "MATLAB")       # Reason: MATLAB
  features[:TEST_POSSIBLE] &= !(pkg_name == "MATLABCluster") # Reason: MATLAB
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mongo")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mongrel2")     # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Mosek")        # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "OpenCL")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "OpenGL")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Pandas")       # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "ProfileView")  # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "PyCall")       # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "PyLexYacc")    # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "PyPlot")       # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "PySide")       # Reason: python
  features[:TEST_POSSIBLE] &= !(pkg_name == "RdRand")       # Reason: needs latest Intel CPU
  features[:TEST_POSSIBLE] &= !(pkg_name == "SemidefiniteProgramming") # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Sodium")       # Reason: binaries
  features[:TEST_POSSIBLE] &= !(pkg_name == "Tk")           # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "Winston")      # Reason: Tk
  features[:TEST_POSSIBLE] &= !(pkg_name == "Vega")         # Reason: weird build
  features[:TEST_POSSIBLE] &= !(pkg_name == "VML")          # Reason: binaries
  
  if !features[:TEST_POSSIBLE]
    features[:TEST_STATUS] = "not_possible"
    return
  end
  
  if features[:TEST_MASTERFILE] == ""
    # Couldn't find a master test file
    # See if "using" works
    testoutput = ""
    try
      fp = open("testusing.jl","w")
      write(fp, "using $pkg_name\n")
      close(fp)
      testoutput = readall(`julia testusing.jl`)
      features[:TEST_STATUS] = "using_pass"
    catch
      # Didn't run without errors
      features[:TEST_STATUS] = "using_fail"
    end
  else
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
