#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# Combines the JSON files in a folder into one
#######################################################################

import JSON

# ARGS[1]: Folder containing JSONs
# ARGS[2]: Output filename (excluding .json)
@assert length(ARGS) == 2

# Parse each JSON and combine
all_pkgs = Dict[]
for file in readdir(ARGS[1])
    !ismatch(r"json", file) && continue
    try
        push!(all_pkgs, JSON.parsefile(joinpath(ARGS[1],file)))
    catch e
        if isa(e, SystemError)
            # Propbably mmap failure due to empty file
            println("$file: $(e.prefix)")
        else
            println("Error for $file:")
            println(e)
        end
    end
end

# Then write them all to one big file
println("Writing $(length(all_pkgs)) packages to $(ARGS[2]).json")
cat_fp = open("$(ARGS[2]).json","w")
JSON.print(cat_fp, all_pkgs)
close(cat_fp)