export scorePkg

const REQUIRE_EXISTS = 20.
const REQUIRE_VERSION = 20.
const LICENSE_EXISTS = 10.
const LICENSE = 0.
const LICENSE_FILE = 0.
const TEST_EXISTS = 20.
const TEST_RUNTESTS = 10.
const TEST_PASSES = 20.
const TEST_NOWARNING = 10.
const TEST_TRAVIS = 10.
const MAX_PKG_SCORE = REQUIRE_EXISTS + REQUIRE_VERSION + LICENSE_EXISTS + 
                      TEST_EXISTS + TEST_RUNTESTS + TEST_PASSES + TEST_NOWARNING + TEST_TRAVIS

const URL_EXISTS = 20.
const DESC_EXISTS = 20.
const REQUIRES_OK = 20.
const REQUIRES_FAILS = 0.
const REQUIRES_PASSES = 0.
const MAX_METADATA_SCORE = URL_EXISTS + DESC_EXISTS + REQUIRES_OK


macro scoreMsg(key, msg, fatal)
  esc(quote
    write(o, $msg)
    if features[$key]
      total_score += eval($key)
      write(o, "    - ✓ Passed (+$(eval($key)))\n")
    else
      write(o, "    - ✗ Failed!\n")
      fatal_error = fatal_error || (true && $fatal)
    end
  end)
end

function scorePkg(features, pkg_name, pkg_path, metadata_path, o = STDOUT)

  total_score = 0.
  max_score = 0.
  fatal_error = false

  write(o, "# $pkg_name\n\n")
  #write(o, "- Local path: $pkg_path\n")
  #write(o, "- METADATA path: $metadata_path\n")

  if pkg_path != ""
    max_score += MAX_PKG_SCORE
    write(o, "\n## Package Itself\n")
    write(o, "\n### REQUIRE file\n")
    @scoreMsg(:REQUIRE_EXISTS,  "- Requirement: packages must have a REQUIRE file\n", true)
    @scoreMsg(:REQUIRE_VERSION, "- Requirement: REQUIRE file specifies a Julia version\n", true)

    write(o, "\n### Licensing\n")
    @scoreMsg(:LICENSE_EXISTS,  "- Recommendation: Packages should have a license\n", false)
    if features[:LICENSE_EXISTS]
      write(o, " - License detected in $(features[:LICENSE_FILE]): $(features[:LICENSE])\n")
    end

    write(o, "\n### Testing\n")
    @scoreMsg(:TEST_EXISTS,   "- Recommendation: Packages should have tests\n", false)
    if features[:TEST_EXISTS]
      @scoreMsg(:TEST_PASSES,    "- Requirement: If tests exist, they should pass.\n", true)
      #@scoreMsg(:TEST_NOWARNING, "- Recommendation: If tests exist, they should not have any warnings.\n", false)
    end
    @scoreMsg(:TEST_RUNTESTS, "- Recommendation: Packages should have a test/runtests.jl file\n", false)
    @scoreMsg(:TEST_TRAVIS,   "- Recommendation: Packages should have TravisCI support\n", false)
  end

  if metadata_path != ""
    max_score += MAX_METADATA_SCORE
    write(o, "\n## Package METADATA Entry\n")
    write(o, "\n### url file\n")
    @scoreMsg(:URL_EXISTS, "- Requirement: Packages must have a url file\n", true)

    write(o, "\n### DESCRIPTION.md file\n")
    @scoreMsg(:DESC_EXISTS, "- Recommendation: Packages should have a DESCRIPTION.md file\n", false)

    write(o, "\n### requires files\n")
    @scoreMsg(:REQUIRES_OK, "- Requirement: Each package version requires file must specify a Julia version\n", true)
    if !features[:REQUIRES_OK]
      write(o, "- Failed versions:\n")
      for version in features[:REQUIRES_FAILS]
        write(o, "    - $version\n")
      end
      write(o, "- Passed versions:\n")
      for version in features[:REQUIRES_PASSES]
        write(o, "    - $version\n")
      end
    end
  end

  write(o, "\n---\n")
  write(o, "\n## Summary\n")

  write(o, " - Total score: $total_score out of $max_score\n")
  if fatal_error
    write(o, " - One or more requirements failed - please fix and try again.\n\n")
  end

  write(o, "\n---\n\n## Raw Features\n")
  for k in keys(features)
    if k == :REQUIRES_PASSES || k == :REQUIRES_FAILS
      write(o, "    $k == [$(join(features[k]," "))]\n")
    else
      write(o, "    $k == $(features[k])\n")
    end
  end

  return total_score / max_score
end

