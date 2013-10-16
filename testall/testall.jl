# Load in package evaluator
using PackageEvaluator

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
  score = evalPkg(pkg_name, true, o)
  close(o)

  done = done + 1
#  if done >= 5
#    break
#  end
end
