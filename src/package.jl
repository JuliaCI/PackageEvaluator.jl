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
  possible_files = [joinpath(pkg_path, "LICENSE"),
                    joinpath(pkg_path, "LICENSE.md"),
                    joinpath(pkg_path, "LICENSE.txt"),
                    joinpath(pkg_path, "README"),
                    joinpath(pkg_path, "README.md"),
                    joinpath(pkg_path, "README.txt"),
                    joinpath(pkg_path, "COPYING"),
                    joinpath(pkg_path, "COPYING.md"),
                    joinpath(pkg_path, "COPYING.txt")]
  for filename in possible_files
    if isfile(filename)
      if guessLicense(features, filename)
        # Stop once we identify a license  
        return
      end
    end
  end
end

function guessLicense(features, filename)
  # Be greedy, read the whole file
  text = lowercase(readall(filename))

  # MIT License
  if ismatch(r"mit license", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "MIT"
  # GPL v2
  elseif ismatch(r"gpl version 2", text) ||
         ismatch(r"gnu general public license\s+version 2", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v2"
  # GPL v3
  elseif ismatch(r"gpl version 3", text) ||
         ismatch(r"http://www.gnu.org/licenses/gpl-3.0.txt", text) ||
         ismatch(r"gnu general public license\s+version 3", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v3"
  # LGPL v2.1
  elseif ismatch(r"lgpl version 2.1", text) ||
         ismatch(r"gnu lesser general public license\s+version 2\.1", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "LGPL v2.1"
  # No license identified
  else
    return false
  end

  # Set the license type
  features[:LICENSE_FILE] = filename
  return true
end


###############################################################################
# Testing folder/files
function checkTesting(features, pkg_path, pkg_name)
  features[:TEST_EXIST] = false

  # First of all, check for the existence of a test folder with Julia
  # files in it
  possible_folders = [joinpath(pkg_path, "test"),
                      joinpath(pkg_path, "tests")]
  for folder in possible_folders
    try
      # ls the folder
      file_list = split(readall(`ls $tests_folder`), "\n")
      # if that didn't die, look through the files
      for file in file_list
        # Any Julia files in there?
        if file[(end-2):(end)] == ".jl"
          features[:TEST_EXIST] = true
          break
        end
      end
    catch
      # No test folder at all
    end
  end

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
    joinpath(pkg_path,          "tests.jl")]
  features[:TEST_MASTERFILE] = ""
  for filename in possible_files
    if isfile(filename)
      features[:TEST_MASTERFILE] = filename
      features[:TEST_EXIST] = true
      break
    end
  end

  features[:TEST_STATUS] = ""
  if features[:TEST_MASTERFILE] == ""
    # Couldn't find a master test file
    # See if "using" works
    testoutput = ""
    try
      testoutput = readall(`julia -e 'using $pkg_name'`)
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
      testoutput = readall(`julia $(features[:TEST_MASTERFILE])`)
      features[:TEST_STATUS] = "full_pass"
    catch
      # Has tests, and they failed
      features[:TEST_STATUS] = "full_fail"
    end
  end

  # Finally, do they have a .travis.yml file?
  travis_file = joinpath(pkg_path, ".travis.yml")
  features[:TEST_TRAVIS] = isfile(travis_file)
end
