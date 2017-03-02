#!/usr/bin/env julia

pkgevalpath = dirname(dirname(@__FILE__))
websitepath = joinpath(pkgevalpath, "../github/pkg.julialang.org")

cd(joinpath(pkgevalpath, "scripts"))

if haskey(ENV, "SSH_AUTH_SOCK")
    warn("SSH_AUTH_SOCK env var set, vagrant may not work")
end

function makebackup(prefix)
    for l in 'a':'z'
        message = "$prefix$l"
        if l == 'z'
            error("Ran $prefix more than 25 times, something is probably wrong")
        elseif isdir(message)
            continue
        else
            mkdir(message)
            run(`sh -c "cp -a *.out.txt $message"`)
            run(ignorestatus(`sh -c "cp -a 0.* $message"`))
            return message
        end
    end
end

today = Date(now())
if any(x->endswith(x,".out.txt"), readdir())
    makebackup("$today-fail") # make backup of old pkgeval logs if present
end

run(`git pull`) # update pkgeval repo to latest before running
run(`./runvagrant.sh`)
message = makebackup(today) # make backup of new logs

cd(websitepath)
run(`git pull`) # update website repo to latest before building new content
cd(Pkg.dir("METADATA"))
run(`git checkout metadata-v2`) # don't leave any work detached on this machine
run(`git pull`) # also update metadata?

cd(joinpath(pkgevalpath, "website"))
run(ignorestatus(`./clean.sh`))
run(`./build.sh`)
token = readchomp("token")

cd("../scripts")
run(`./clean.sh`)

cd(websitepath)
run(`git config user.name "The Nanosoldier"`)
run(`git config user.email jrevels@csail.mit.edu`)
run(`git add .`)
run(`git commit -m "$message"`)
run(`git remote add $token https://$token:x-oauth-basic@github.com/JuliaCI/pkg.julialang.org`)
run(`git push $token gh-pages`)
run(`git remote rm $token`)

println("Done pushing website!")
cd(joinpath(pkgevalpath, "scripts"))
run(ignorestatus(`mv log.txt $message`))
println("Compressing logs at $message")
run(`tar -cJf $message.tar.xz $message`)
println("Deleting uncompressed logs from $message")
run(`rm -rf $message`)
