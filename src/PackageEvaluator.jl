module PackageEvaluator

export evalPkg, scorePkg

const REQUIRE_EXISTS = 20.
const REQUIRE_VERSION = 20.
const LICENSE_EXISTS = 10.
const LICENSE = 0.
const LICENSE_FILE = 0.
const TEST_RUNTESTS = 20.
const TEST_TRAVIS = 10.
const MAX_SCORE = REQUIRE_EXISTS + REQUIRE_VERSION + LICENSE_EXISTS + TEST_RUNTESTS + TEST_TRAVIS

# Evaluate the package itself
include("package.jl")

macro scoreMsg(key, msg, fatal)
  quote
    write(o, $msg)
    if features[$key]
      total_score += eval($key)
      write(o, " - ✓ Passed (+$(eval($key)))\n")
    else
      write(o, " - ✗ Failed!\n")
      fatal_error = true && $fatal
    end
  end
end

function scorePkg(features, o = STDOUT)

  total_score = 0.
  fatal_error = false

  write(o, "# Package Analysis Results\n")

  write(o, "## Package Itself\n")
  write(o, "### REQUIRE file\n")
  @scoreMsg(:REQUIRE_EXISTS,  "- Requirement: packages must have a REQUIRE file\n", true)
  @scoreMsg(:REQUIRE_VERSION, "- Requirement: REQUIRE file specifies a Julia version\n", true)

  write(o, "\n### Licensing\n")
  @scoreMsg(:LICENSE_EXISTS,  "- Recommendation: Packages should have a license\n", false)
  if features[:LICENSE_EXISTS]
    write(o, " - License detected in $(features[:LICENSE_FILE]): $(features[:LICENSE])\n")
  end

  write(o, "\n### Testing\n")
  @scoreMsg(:TEST_RUNTESTS, "- Requirement: Packages must have a test/runtests.jl file\n", true)
  @scoreMsg(:TEST_TRAVIS,   "- Recommendation: Packages should have TravisCI support\n", false)


  write(o, "\n---\n")
  write(o, "\n## Summary\n")
  write(o, " - Total score: $total_score out of $MAX_SCORE\n")
  if fatal_error
    write(o, " - One or more requirements failed - please fix and try again.\n")
  end

end


function evalPkg(pkg_path)
  features = Dict{Symbol,Any}()

  checkREQUIRE(features, pkg_path)
  checkLicense(features, pkg_path)
  checkTesting(features, pkg_path)

  scorePkg(features)
end

end
