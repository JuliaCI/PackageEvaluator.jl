@assert length(ARGS) == 2

# Load all the JSONs just as strings
raw_files = {}
for file in readdir(ARGS[1])
    !ismatch(r"json", file) && continue
    contains(file, "concat.json") && continue
    push!(raw_files, readall(joinpath(ARGS[1],file)))
end

# Then write them all to one big file
cat_fp = open("$(ARGS[2]).json","w")
println(cat_fp, "[",join(raw_files,","),"]")
close(cat_fp)