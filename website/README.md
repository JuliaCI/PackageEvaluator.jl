# Building pkg.julialang.org from PackageEvaluator

Depending on the configuration it is run in, PkgEval will produce either

* `release.` and `nightly.json`, or
* `releaseAL.`, `releaseMZ.`, `nightlyAL.`, `nightlyMZ.json`.

The scripts in this folder take these results, enhance them, and contruct
the HTML and images for the website.

#### Required packages

* Julia packages: `JSON.jl`, `GitHub.jl`, `MetadataTools.jl`, `Mustache.jl`, `JLD.jl`, `Requests.jl`

#### 1. `pull_repo_info.jl`

Use the GitHub API to pull information about the repository itself.
Currently that is just the description of the package and the number
of stars. Saves results in `pkg_repo_infos.jld`, and assumes a Github
token is stored in working directory in a `token` file.

#### 2. `update_db.jl`

Take the results and repository information, and update the test and
start history databases.