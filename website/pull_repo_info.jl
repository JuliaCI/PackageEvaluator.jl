#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/pull_repo_info.jl
# Use the GitHub API to pull information about the repository itself.
# Currently that is just the description of the package and the number
# of stars. Saves results in `pkg_repo_infos.jld`, and assumes a Github
# token is stored in working directory in a `token` file.
#-----------------------------------------------------------------------

using JSON, GitHub, JLD

# Load raw PkgEval data
if length(ARGS) == 2
    # release/nightly
    R = JSON.parsefile(ARGS[1])
    N = JSON.parsefile(ARGS[2])
    all_pkgs = vcat(R,N)
elseif length(ARGS) == 4
    # releaseAL|MZ/nightlyAL|MZ
    RAL = JSON.parsefile(ARGS[1])
    RMZ = JSON.parsefile(ARGS[2])
    NAL = JSON.parsefile(ARGS[3])
    NMZ = JSON.parsefile(ARGS[4])
    all_pkgs = vcat(RAL,RMZ,NAL,NMZ)
else
    error("""
        Expected either 2 path arguments (release.json, nightly.json),
        or 4 path arguments (releaseAL/MZ, nightlyAL/MZ).""")
end

# Cache concatenated JSON
println("Saving concatenated JSON")
fp = open("all.json","w")
print(fp, JSON.json(all_pkgs))
close(fp)

# Collect all the package names and owners
pkg_repos = Set()
for pkg in all_pkgs
    pkg_name   = pkg["name"]
    repo_name  = split(pkg["url"],"/")[end]
    repo_owner = split(pkg["url"],"/")[end-1]
    push!(pkg_repos, (pkg_name, repo_name, repo_owner))
end
println("Number of packages: ", length(pkg_repos))

# Authenticate with Github
gh_auth = authenticate(readall("token"))

# Retrieve information
pkg_repo_infos = Dict()
for (pkg_name, repo_name, repo_owner) in pkg_repos
    print((pkg_name, repo_owner, repo_name))
    println(" (", length(pkg_repo_infos)/length(pkg_repos)*100, "%)")
    repo_info = try
        repo(repo_owner, repo_name, auth=gh_auth)
    catch err
        println("Couldn't get info for ", repo_owner, "/", repo_name)
        println(err)
        nothing
    end
    pkg_repo_infos[pkg_name] = repo_info
end

# Save information in a JLD file
println("Saving repository data...")
save("pkg_repo_infos.jld", "pkg_repo_infos", pkg_repo_infos)
println("Done saving data")