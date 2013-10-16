# Load in package evaluator
using PackageEvaluator

# Setup the index file
summary = open("index.html","w")
preindex = open("preindex.inc","r")
write(summary, readall(preindex))
close(preindex)

# Setup the table
keyorder = [:REQUIRE_EXISTS, :REQUIRE_VERSION, :LICENSE,
            :TEST_EXISTS, :TEST_RUNTESTS, :TEST_PASSES, :TEST_NOWARNING, :TEST_TRAVIS,
            :URL_EXISTS, :DESC_EXISTS, :REQUIRES_OK]
headers = ["Package", "Score", "REQUIRE<br>exists", "REQUIRE<br>Julia ver.", "License", "Has any", "runtests.jl<br>exists", "Pass?", "No warnings?", "TravisCI?", "url<br>exists", "DESCRIPTION.md<br>exists", "requires<br>Julia ver."]
write(summary, "<table>\n")
write(summary, "<tr><td colspan=\"3\"></td><td colspan=\"2\">Package</td><td colspan=\"5\">Tests</td><td colspan=\"3\">METADATA</td></tr>\n")
for h in headers
  write(summary, "<td>$h</td>")
end
write(summary,"</tr>\n")

# Walk through each package
available_pkg = Pkg.available()
done = 0
for pkg_name in available_pkg

  # Check if we have already made the file
  if isfile(string(pkg_name, ".md"))
    continue
  end

  # Check the exception list
  if pkg_name == "MinimalPerfectHashes"
    continue
  end

  # Run PackageEvaluator
  o = open(string(pkg_name,".md"), "w")
  score, features = evalPkg(pkg_name, true, o)
  close(o)

  # Write a row
  write(summary, "<tr><td><a href=\"$(pkg_name).html\">$pkg_name</a></td>")
  write(summary, "<td>$(int(round(score*100)))%</td>")
  for k in keyorder
    if k in keys(features)
      write(summary, "<td>$(features[k])</td>")
    else
      write(summary, "<td></td>")
    end
  end
  write(summary, "</tr>\n")

  done = done + 1
  if done >= 2
    break
  end
end

write(summary, "</table></div></div></body></html>")
close(summary)
