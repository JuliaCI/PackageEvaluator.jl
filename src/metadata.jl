###############################################################################
# url file
function checkURL(features, metadata_path)
  url_path = joinpath(metadata_path, "url")
  features[:URL_EXISTS] = isfile(url_path)
end

###############################################################################
# DESCRIPTION.md file
function checkDesc(features, metadata_path)
  desc_path = joinpath(metadata_path, "DESCRIPTION.md")
  features[:DESC_EXISTS] = isfile(desc_path)
end


