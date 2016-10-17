#!/usr/bin/env julia

cd(dirname(@__FILE__)) do
    contents = readdir()
    for f in contents
        if isdir(f) && ismatch(r"\d\d\d\d-\d\d-\d\d.*", f) && !("$f.tar.xz" in contents)
            println("Compressing logs from $f")
            run(`tar -cJf $f.tar.xz $f`)
            println("Deleting uncompressed logs from $f")
            run(`rm -rf $f`)
        end
    end
end
