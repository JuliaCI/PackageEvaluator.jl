using PackageEvaluator
features = evaluatePackage("https://github.com/IainNZ/JuMP.jl.git")
scorePackage(features)
println("")
features = evaluatePackage("https://github.com/JuliaLang/Example.jl.git")
scorePackage(features)
