module PackageEvaluator

export evaluatePackage, scorePackage

const REQUIRE_EXISTS = 1.
const REQUIRE_VERSION = 1.
const LICENSE_EXISTS = 1.
const LICENSE = 0.
const LICENSE_FILE = 0.

function scorePackage(features)

  total_score = 0.
  fatal_error = false

  println("\n# Package Analysis Results")
  println("\n## REQUIRE file")
  println("- Requirement: packages must have a REQUIRE file")
  if features[:REQUIRE_EXISTS]
    total_score += REQUIRE_EXISTS
    println(" - ✓ Passed (+$REQUIRE_EXISTS)")
  else
    println(" - ✗ Failed!")
    fatal_error = true
  end

  println("- Requirement: REQUIRE file specifies a Julia version")
  if features[:REQUIRE_VERSION]
    total_score += REQUIRE_VERSION
    println(" - ✓ Passed (+$REQUIRE_VERSION)")
  else
    println(" - ✗ Failed!")
    fatal_error = true
  end

  println("\n## Licensing")
  println("- Recommendation: Packages should have a license")
  if features[:LICENSE_EXISTS]
    total_score += LICENSE_EXISTS
    println(" - ✓ Passed (+$LICENSE_EXISTS)")
    println("  - Detected license in $(features[:LICENSE_FILE]): $LICENSE")
  else
    println(" - ✗ Failed!")
  end
  println("\n---")
  println("\n## Summary")
  println(" - Total score: $total_score")
  if fatal_error
    println(" - One or more requirements failed - please fix and try again.")
  end

end


function evaluatePackage(repo_url)
  features = Dict{Symbol,Any}()

  # Extract repository name
  pkg_name = split(repo_url, "/")[end][1:(end-4)]
  # Clone to local directory
  println("Cloning package '$pkg_name'...")
  run(`git clone $repo_url`)
  println("Done!")

  # Begin checks
  checkREQUIRE(features, pkg_name)
  checkLicense(features, pkg_name)

  #println(features)

  # Clean up
  run(`rm -rf $pkg_name`)

  return features
end

function checkREQUIRE(features, pkg_name)
  REQUIRE_path = joinpath(pkg_name, "REQUIRE")
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

function checkLicense(features, pkg_name)

  # Test for some sort of license file first
  possible_files = [joinpath(pkg_name, "LICENSE"),
                    joinpath(pkg_name, "LICENSE.md"),
                    joinpath(pkg_name, "README"),
                    joinpath(pkg_name, "README.md")]
  for filename in possible_files
    if isfile(filename)
      if guessLicense(features, filename)
        return
      end
    end
  end      
    
  # Failed
  features[:LICENSE_EXISTS] = false
  features[:LICENSE] = "Unknown"
  features[:LICENSE_FILE] = ""
end

function guessLicense(features, filename)
  # Be greedy, read the whole file
  # TODO: Make [key: license, value: list of possibilities] pairs, loop
  println("Looking in $filename for license...")
  text = lowercase(readall(filename))
  if ismatch(r"mit license", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "MIT"
  elseif ismatch(r"gpl version 2", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v2"
  elseif ismatch(r"gpl version 3", text) ||
         ismatch(r"http://www.gnu.org/licenses/gpl-3.0.txt", text)
    features[:LICENSE_EXISTS] = true
    features[:LICENSE] = "GPL v3"
  else
    return false
  end
  features[:LICENSE_FILE] = filename
  return true
end

end
