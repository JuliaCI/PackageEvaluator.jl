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
#cloneRepo("https://github.com/IainNZ/JuMP.jl.git")
#evalPkg("JuMP.jl")
#cleanRepo("JuMP.jl")

# Example.jl
#cloneRepo("https://github.com/JuliaLang/Example.jl.git")
#evalPkg("Example.jl")
#cleanRepo("Example.jl")

# Ourselves
evalPkg(".")
