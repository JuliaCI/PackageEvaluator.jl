# Load in package evaluator
using PackageEvaluator

# Walk through each package
available_pkg = Pkg.available()
done = 0
for pkg_name in available_pkg

# For now cheat and cherry pick one
#pkg_name = "Distributions"

  # Run PackageEvaluator
  o = open(string(pkg_name,".md"), "w")
  score = evalPkg(pkg_name, true, o)
  close(o)

  done = done + 1
  if done >= 5
    break
  end
end
