function catall(ver)
    x = {}
    for file in readdir(ver)
        (!ismatch(r"json", file) || contains(file, "concat.json")) && continue
        push!(x, readall(joinpath(ver,file)))
    end
    return join(x,",")
end

cat_fp = open("all.json","w")
println(cat_fp, catall("stable"), ",", catall("nightly"))
close(cat_fp)