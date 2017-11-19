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

# Recent versions of Vagrant exit with a nonzero status from `vagrant destroy` if a
# VM isn't running (https://github.com/hashicorp/vagrant/issues/9137). Vagrant knows
# about more VMs than we actually spawn, so the status is nonzero even if everything
# finished normally. Thus we have to ignore the status and instead manually check
# whether it's safe to continue.
isfile("vagrant.out.txt") && rm("vagrant.out.txt")
run(pipeline(ignorestatus(`./runvagrant.sh`),
             stdout="vagrant.out.txt",
             stderr="vagrant.out.txt",
             append=true))
prevline = ""
for line in eachline("vagrant.out.txt")
    # If the last thing that happened before tearing down the VMs wasn't provisioning
    # them, something must have gone wrong
    if ismatch(r"^==> [^:]+: Forcing shutdown", line) &&
        !ismatch(r"^Provisioning '[^']+'. Output will be in", prevline)
        error("Something went wrong while running Vagrant. See vagrant.out.txt.")
    end
    prevline = line
end
# prevline now contains the last line, so make sure it's a typical Vagrant message
if !ismatch(r"^==> [^:]+: (Destroying VM and|VM not created)", prevline)
    error("Something went wrong while running Vagrant. See vagrant.out.txt")
end
# TODO: Remove this whole terrible hack once Vagrant issue #9137 is fixed.

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
