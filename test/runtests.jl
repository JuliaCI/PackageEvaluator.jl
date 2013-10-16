using PackageEvaluator

function cloneRepo(repo_url)
  # Extract repository name
  pkg_name = split(repo_url, "/")[end][1:(end-4)]
  # Clone to local directory
  println("Cloning package '$pkg_name'...")
  run(`git clone $repo_url`)
  println("Done!")
end

function cleanRepo(pkg_name)
  # Clean up
  run(`rm -rf $pkg_name`)
end


# JuMP
#evalPkg("JuMP",false)

# Example.jl
evalPkg("Example")

# Ourselves (infinite loop!)
#evalPkgFromPaths(Pkg.dir("PackageEvaluator"), joinpath(Pkg.dir("PackageEvaluator"),"test", "METADATATest"))
