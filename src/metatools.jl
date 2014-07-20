#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################
# MetaTools module
# Tools for working with METADATA.jl
#######################################################################

module MetaTools

#######################################################################
# PkgMeta - represents a packages entry in METADATA.jl
# PkgMetaVersion - represents a version of a package in METADATA.jl
type PkgMetaVersion
    ver::VersionNumber
    sha::String
    requires::Vector{String}
end
type PkgMeta
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
    map(println, pm.versions)
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
    pkg_path = joinpath(meta_path,pkg_name)
    !isdir(pkg_path) && error("Couldn't find $pkg_name at $pkg_path")
    
    url_path = joinpath(pkg_path,"url")
    !isfile(url_path) && error("Couldn't find url for $pkg_name (expected $url_path)")
    url = chomp(readall(url_path))

    vers_path = joinpath(pkg_path,"versions")
    println(vers_path, "---", isdir(vers_path))
    !isdir(pkg_path) &&
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
    return PkgMeta(pkg_name, url, vers)
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
        println(ver)
        julia_max_ver = v"0.0.0"
        for req in ver.requires
            !contains(req,"julia") && continue
            s = split(req," ")
            length(s) != 3 && continue
            julia_max_ver = convert(VersionNumber,s[3])
            break
        end
        println(julia_max_ver, " ", all_max, " ", upper)
        if julia_max_ver == v"0.0.0"
            all_max = false
            break
        else
            if julia_max_ver > upper
                upper = julia_max_ver
            end
        end
    end
    return all_max ? upper : v"0.0.0"
end

end  # module

function load_first_degree()
    first_degree = Dict()

    cd("METADATA.jl")
    for name in readdir()
        (!isdir(name) || name[1] == '.') && continue
        first_degree[name] = {}
        cd(name)
        if isdir("versions")
            cd("versions")
            vnum = sort(map(x->convert(VersionNumber,x), readdir()))
            temp = IOBuffer(); print(temp,vnum[end])
            max_vnum = takebuf_string(temp)
            cd(max_vnum)
            if isfile("requires")
                open("requires","r") do fp
                    for line in readlines(fp)
                        push!(first_degree[name], chomp(line))
                    end
                end
            end
            cd("../..")
        end
        cd("..")
    end
    cd("..")
    return first_degree
end

function clean_first_degree(first_degree)
    function filt(dep)
        contains(dep,"julia") && return false
        return true
    end
    for name in keys(first_degree)
        #println(first_degree[name])
        clean = {}
        for dep in first_degree[name]
            contains(dep,"julia") && continue
            length(dep) == 0 && continue
            dep[1] == '#' && continue
            s = split(dep," ")
            if length(s) == 1
                push!(clean,dep)
            elseif s[1][1] == '@'
                push!(clean,s[2])
            else # trim version
                push!(clean,s[1])
            end
        end
        first_degree[name] = clean
    end
    return first_degree
end

function dump_all(first_degree)
    numbered = Dict()
    dep_on = Dict()

    for key in keys(first_degree)
        for dep in first_degree[key]
            dep_on[dep] = true
            dep_on[key] = true
        end
    end
    i = 1
    for key in keys(first_degree)
        #!get(dep_on,key,false) && continue
        numbered[key] = i
        i+=1
    end
    N = i - 1
    adj_matrix = zeros(Int, N, N)
    names = ["" for i in 1:N]

    fp = open("graph.txt","w")
    for key in keys(first_degree)
        #!get(dep_on,key,false) && continue
        names[numbered[key]] = key
        for dep in first_degree[key]
            adj_matrix[numbered[key], numbered[dep]] = 1
            #println(fp, numbered[key], " ", numbered[dep])
        end
    end
    println(fp,",",join(names,","))
    for i = 1:N
        println(fp,names[i],",",join([string(adj_matrix[i,j]) for j in 1:N],","))
    end
    close(fp)
end

function make_tree(base, first_degree)
    depth = Dict()

    depth[base] = 0
    cur_depth = 0
    while true
        added_new = false
        for key in keys(first_degree)
            if get(depth, key, -1) == cur_depth
                #println(first_degree[key])
                for dep in first_degree[key]
                    if get(depth, dep, -1) == -1
                        depth[dep] = cur_depth + 1
                        added_new = true
                    end
                end
            end
        end
        cur_depth += 1
        !added_new && break
    end

    println(depth)

    return depth
end


function dump_sub_tree(first_degree, include_in)
    numbered = Dict()

    i = 1
    for key in keys(first_degree)
        !(key in keys(include_in)) && continue
        numbered[key] = i
        i+=1
    end
    N = i - 1
    adj_matrix = zeros(Int, N, N)
    names = ["" for i in 1:N]

    
    for key in keys(first_degree)
        !(key in keys(include_in)) && continue
        names[numbered[key]] = key
        for dep in first_degree[key]
            adj_matrix[numbered[key], numbered[dep]] = 1
        end
    end

    fp = open("graph_names.txt","w")
    print(fp,join(names,"\n"))
    close(fp)

    fp = open("graph.txt","w")
    for i = 1:N
        println(fp, join([string(adj_matrix[i,j]) for j in 1:N],","))
    end
    close(fp)
end


#=
first_degree = clean_first_degree(load_first_degree())
gadfly_tree = make_tree("Gadfly", first_degree)
dump_sub_tree(first_degree, gadfly_tree)
=#
