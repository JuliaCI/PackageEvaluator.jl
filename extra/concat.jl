cat_fp = open("concat.json","w")
first = true
for file in readdir()
    (!ismatch(r"json", file) || contains(file, "concat.json")) && continue

    !first && print(cat_fp, ",")
    first = false
    println(cat_fp, readall(file))
end
close(cat_fp)