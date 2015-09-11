# Building pkg.julialang.org from PackageEvaluator

Depending on the configuration it is run in, PkgEval will produce either

* `release.` and `nightly.json`, or
* `releaseAL.`, `releaseMZ.`, `nightlyAL.`, `nightlyMZ.json`.

The scripts in this folder take these results, enhance them, and contruct
the HTML and images for the website. If you have everything installed,
you should open up `build.sh` and modify the paths for your system. It
will then run through all the components.

**Required packages**:
`Gadfly.jl`,
`GitHub.jl`,
`Humanize.jl`,
`JLD.jl`, 
`JSON.jl`,
`MetadataTools.jl`,
`Mustache.jl`,
`Requests.jl`

#### 1. `pull_repo_info.jl`

Use the GitHub API to pull information about the repository itself.
Currently that is just the description of the package and the number
of stars. Saves results in `pkg_repo_infos.jld`, and assumes a Github
token is stored in working directory in a `token` file.

#### 2. `update_db.jl`

Take the results and repository information, and update the test and
start history databases.

#### 3. `build_site_data.jl`

Take the results and repository information, and produce a single
JSON with all information required to construct the website. At the
same time, produce all badges and log files from the package info.

#### 4. `build_index.jl`

The main page is built by combining a header, a footer, and then
repeating a middle chunk for every package. The templates are stored
in the `website/html/` subfolder, and are populated using `Mustache`.

#### TODO: bring `plot_pkg` and `build_pulse` over