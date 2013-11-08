###############################################################################
# testAll
# Performs all tests on all packages in METADATA single package.
# Outputs an index.html file containing a table of results
export testAll

writeKey(json, key, value::String, last=false) = write(json, "  \"$key\": \"$value\"$(!last?",":"")\n")

function writeJSON(pkg_name, features)
  json = open("$pkg_name.json", "w")

  write(json, "{\n")
  writeKey(json, "name", pkg_name)
  writeKey(json, "url", features[:URL])
  writeKey(json, "license", features[:LICENSE])
  writeKey(json, "status", features[:TEST_STATUS])
  writeKey(json, "details", getDetailsString(pkg_name, features))
  writeKey(json, "pkgreq", features[:REQUIRE_VERSION] ? "true" : "false")
  writeKey(json, "metareq", features[:REQUIRES_OK] ? "true" : "false")
  writeKey(json, "travis", features[:TEST_TRAVIS] ? "true" : "false", true)
  write(json, "}")

  close(json)
end

function getDetailsString(pkg_name, features)
  t_exist = features[:TEST_EXIST]
  t_status = features[:TEST_STATUS]
  t_master = features[:TEST_MASTERFILE]
  
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

function testAll(limit = Inf, writeJSONs=true)

  summary = open("index.html","w")

  # Setup the index file by copying in a header from a file in 
  # the extra/ folder
  preindex_path = joinpath(Pkg.dir("PackageEvaluator"),"extra","preindex.inc")
  preindex = open(preindex_path,"r")
  write(summary, readall(preindex))
  close(preindex)

  # Walk through each package in METADATA (assume updated)
  available_pkg = Pkg.available()
  done = 0
  for pkg_name in available_pkg



    # Check if we have already made the package description file
    #if isfile(string(pkg_name, ".md"))
    #  continue
    #end

    # Check the exception list
    if pkg_name == "MinimalPerfectHashes"
      continue
    end

    # Run any preprocessing
    exceptions_before(pkg_name)

    # Run PackageEvaluator
    #o = open(string(pkg_name,".md"), "w")
    #score, features = evalPkg(pkg_name, true, o)
    #close(o)
    features = evalPkg(pkg_name, true)  # add and remove it

    # Run any postprocessing
    exceptions_after(pkg_name)

    # Write a row
    #write(summary, "<tr><td><a href=\"$(pkg_name).html\">$pkg_name</a></td>")
    write(summary, "<tr>\n")
    # Package
    write(summary, "  <td>$pkg_name</td>\n")
    # Repo
    write(summary, "  <td><a href=\"$(features[:URL])\">$(pkg_name).jl</a></td>\n")
    # License
    if features[:LICENSE] == "Unknown"
      write(summary, "  <td class=\"red\">?</td>")
    else
      write(summary, "  <td class=\"grn\">$(features[:LICENSE])</td>\n")
    end
    
    # Testing
    write(summary, "  <td class=\"$(features[:TEST_STATUS]) thk\"></td>")
    details = getDetailsString(pkg_name, features)
    write(summary, "  <td>$details</td>\n")
    
    # Pkg req
    if features[:REQUIRE_VERSION]
      write(summary, "  <td class=\"grn thk\"></td>")
    else
      write(summary, "  <td class=\"thk\"></td>")
    end
    # META req
    if features[:REQUIRES_OK]
      write(summary, "  <td class=\"grn\"></td>")
    else
      write(summary, "  <td></td>")
    end
    # TravisCI
    if features[:TEST_TRAVIS]
      write(summary, "  <td class=\"grn\"></td>")
    else
      write(summary, "  <td></td>")
    end

    write(summary, "</tr>\n")

    # WriteJSON
    if writeJSONs
      writeJSON(pkg_name, features)
    end

    # Limit number of packages to test
    done = done + 1
    if done >= limit
      break
    end
  end

  write(summary, "</table></div></div></body></html>")
  close(summary)
end


###############################################################################
# exceptions_before
# exceptions_after
# Any "special" testing commands to be done
function exceptions_before(pkg_name)
  if pkg_name == "JuMP"
    Pkg.add("Cbc")
    Pkg.add("Clp")
  end
end

function exceptions_after(pkg_name)
  if pkg_name == "JuMP"
    Pkg.rm("Cbc")
    Pkg.rm("Clp")
  end
end

