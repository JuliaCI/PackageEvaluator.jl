###############################################################################
# url file
function checkURL(features, metadata_path)
  url_path = joinpath(metadata_path, "url")
  features[:URL_EXISTS] = isfile(url_path)
  gitpath = chomp(readall(url_path))
  # Remove starting git:// or https://
  if gitpath[1:3] == "git"
    gitpath = gitpath[7:(end-4)]
  elseif gitpath[1:5] == "https"
    gitpath = gitpath[9:(end-4)]
  end
  features[:URL] = string("http://",gitpath)
end

###############################################################################
# DESCRIPTION.md file
function checkDesc(features, metadata_path)
  desc_path = joinpath(metadata_path, "DESCRIPTION.md")
  features[:DESC_EXISTS] = isfile(desc_path)
end

###############################################################################
# require files
function checkRequire(features, metadata_path)
  all_requires_ok = true
  features[:REQUIRES_FAILS] = ASCIIString[]
  features[:REQUIRES_PASSES] = ASCIIString[]

  versions_folder = joinpath(metadata_path, "versions")
  # What is the OS independent way to do this?
  version_list = split(readall(`ls $versions_folder`), "\n")
  for version in version_list[1:(end-1)]
    version_folder = joinpath(versions_folder, version)
    require_file = joinpath(version_folder, "requires")
    file_contents = ""
    try
      file_contents = readall(require_file)
    end
    passes = ismatch(r"julia", file_contents)
    if !passes
      all_requires_ok = false
      push!(features[:REQUIRES_FAILS], version)
    else
      push!(features[:REQUIRES_PASSES], version)
    end
  end
  features[:REQUIRES_OK] = all_requires_ok
end
