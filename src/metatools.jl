#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################
# MetaTools module
# Tools for working with METADATA.jl
#######################################################################

export MetaTools
module MetaTools

#######################################################################
# PkgMeta - represents a packages entry in METADATA.jl
# PkgMetaVersion - represents a version of a package in METADATA.jl
immutable PkgMetaVersion
    ver::VersionNumber
    sha::String
    requires::Vector{String}
end
immutable PkgMeta
    name::String
    url::String
    versions::Vector{PkgMetaVersion}
end

function printer(io::IO, pmv::PkgMetaVersion)
    print("  ", pmv.ver, ",", pmv.sha[1:6])
    map(r->print(",",r), pmv.requires)
end
Base.print(io::IO, pmv::PkgMetaVersion) = printer(io,pmv)
Base.show(io::IO, pmv::PkgMetaVersion) = printer(io,pmv)

function printer(io::IO, pm::PkgMeta)
    println(io, pm.name, "   ", pm.url)
    for v in pm.versions[1:end-1]
        println(v)
    end
    if length(pm.versions) >= 1
        print(pm.versions[end])
    end
end
Base.print(io::IO, pm::PkgMeta) = printer(io,pm)
Base.show(io::IO, pm::PkgMeta) = printer(io,pm)

#######################################################################
# get_pkg 
#   return a structure with all information about the package listed
#   in METADATA, e.g.
#
#   julia> get_pkg("...", "DataFrames")
#   DataFrames   git://github.com/JuliaStats/DataFrames.jl.git
#     0.0.0,a63047,Options,StatsBase
#     0.1.0,7b1c6b,julia 0.1- 0.2-,Options,StatsBase
#     0.2.0,b5f0fe,julia 0.2-,GZip,Options,StatsBase
#     ...
#     0.5.7,a8ae61,julia 0.3-,DataArrays,StatsBase 0.3.9+,GZip,Sort...
#
function get_pkg(meta_path::String, pkg_name::String)
    !isdir(meta_path) && error("Couldn't find METADATA folder at $meta_path")

    pkg_path = joinpath(meta_path,pkg_name)
    !isdir(pkg_path) && error("Couldn't find $pkg_name at $pkg_path")
    
    url_path = joinpath(pkg_path,"url")
    !isfile(url_path) && error("Couldn't find url for $pkg_name (expected $url_path)")
    url = chomp(readall(url_path))

    vers_path = joinpath(pkg_path,"versions")
    !isdir(vers_path) &&
        # No versions tagged
        return PkgMeta(pkg_name, url, PkgMetaVersion[])
    
    vers = PkgMetaVersion[]
    for dir in readdir(vers_path)
        ver_num = convert(VersionNumber, dir)
        ver_path = joinpath(vers_path, dir)
        sha = chomp(readall(joinpath(ver_path,"sha1")))
        req_path = joinpath(ver_path,"requires")
        reqs = String[]
        if isfile(req_path)
            req_file = map(chomp,split(readall(req_path),"\n"))
            for req in req_file
                length(req) == 0 && continue
                req[1] == '#' && continue
                push!(reqs, req)
            end
        end
        push!(vers,PkgMetaVersion(ver_num,sha,reqs))
    end
    # Sort ascending by version number
    sort!(vers, by=(v->v.ver))
    return PkgMeta(pkg_name, url, vers)
end

#######################################################################
# get_all_pkg
# Walks through the METADATA folder, returns a vector of PkgMetas
# for every package found.
function get_all_pkg(meta_path::String)
    !isdir(meta_path) && error("Couldn't find METADATA folder at $meta_path")
    
    pkgs = PkgMeta[]
    for fname in readdir(meta_path)
        # Skip files
        !isdir(joinpath(meta_path, fname)) && continue
        # Skip "hidden" folders
        (fname[1] == '.') && continue
        push!(pkgs, get_pkg(meta_path, fname))
    end

    return pkgs
end

#######################################################################
# get_upper_limit
# Run through all versions of a package to try to determine if there
# is an upper limit on the Julia version this package is installable
# on. Does so by checking all Julia requirements across all versions.
# If there is a limit, returns that version, otherwise v0.0.0
function get_upper_limit(pkg::PkgMeta)
    upper = v"0.0.0"
    all_max = true
    for ver in pkg.versions
        julia_max_ver = v"0.0.0"
        # Check if there is a Julia max version dependency
        for req in ver.requires
            !contains(req,"julia") && continue
            s = split(req," ")
            length(s) != 3 && continue
            julia_max_ver = convert(VersionNumber,s[3])
            break
        end
        # If there wasn't, then at least one version will work on
        # any Julia, so stop looking
        if julia_max_ver == v"0.0.0"
            all_max = false
            break
        else
            # Only record the highest max version
            if julia_max_ver > upper
                upper = julia_max_ver
            end
        end
    end
    return all_max ? upper : v"0.0.0"
end

end  # module