###############################################################################
# PackageEvaluator
###############################################################################
# output.jl
# Output functions for test results
# Exports:
#  featuresToJSON
#  getDetailsString
###############################################################################

# keyToJSON
# Helper function that takes a key and value and writes them in the official 
# JSON format.
function keyToJSON(key, value, last=false)
    return "  \"$key\": \"$value\"$(!last?",":"")\n"
end


# featuresToJSON
# Takes test results and formats them as a JSON string that can be handled 
# by status.julialang.org
export featuresToJSON
function featuresToJSON(pkg_name, features)
    json_str = "{\n"
    json_str = json_str * keyToJSON("name",     pkg_name)
    json_str = json_str * keyToJSON("url",      features[:URL])
    json_str = json_str * keyToJSON("version",  features[:VERSION])
    json_str = json_str * keyToJSON("license",  features[:LICENSE])
    json_str = json_str * keyToJSON("status",   features[:TEST_STATUS])
    json_str = json_str * keyToJSON("possible", features[:TEST_POSSIBLE] ? "true" : "false")
    json_str = json_str * keyToJSON("details",  getDetailsString(pkg_name, features))
    json_str = json_str * keyToJSON("pkgreq",   features[:REQUIRE_VERSION] ? "true" : "false")
    json_str = json_str * keyToJSON("metareq",  features[:REQUIRES_OK] ? "true" : "false")
    json_str = json_str * keyToJSON("travis",   features[:TEST_TRAVIS] ? "true" : "false", true)
    json_str = json_str * "}"
    return json_str
end


# getDetailsString
# Take full results and builds a human-readable string that summarizes the
# testing results (TEST_EXIST, TEST_STATUS, TEST_MASTERFILE)
export getDetailsString
function getDetailsString(pkg_name, features)
  t_exist     = features[:TEST_EXIST]
  t_status    = features[:TEST_STATUS]
  t_master    = features[:TEST_MASTERFILE]
  t_possible  = features[:TEST_POSSIBLE]
  
  if !(t_possible)
    return "This package can't be automatically tested - see package's README."
  end

  details = ""
  if t_exist && t_master == ""
    details = "Tests exist, no master file to run, tried 'using $pkg_name'"
    if t_status == "using_fail"
      details = string(details, ", failed!")
    else
      details = string(details, ", no errors.")
    end
  elseif t_exist && t_master != ""
    details = "Tests exist, ran 'julia $(splitdir(t_master)[2])'"
    if t_status == "full_fail"
      details = string(details, ", failed!")
    else
      details = string(details, ", passed!")
    end
  else
    details = "No tests, tried 'using $pkg_name'"
    if t_status == "using_fail"
      details = string(details, ", failed!")
    else
      details = string(details, ", no errors.")
    end
  end
  

  return details
end