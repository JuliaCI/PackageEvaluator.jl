#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################
# Package ecosystem dependency counter
# Counts the number of dependencies for each package and sorts them
#######################################################################

using PackageEvaluator

# The location of METADATA - can change if needed
const METAPATH = Pkg.dir("METADATA")

#######################################################################
# build_graph
# Walk through all packages in METADATA and assemble a representation
# of the dependency graph in adjacency list format.
function build_graph(pkgs)
    graph = Dict()

    for pkg in pkgs
        # Some packages have no versions, thus unknown deps
        if length(pkg.versions) == 0
            graph[pkg.name] = {}
            continue
        end
        # Has at least one version
        cur_ver = pkg.versions[end]
        graph[pkg.name] = {}
        for req in cur_ver.requires
            contains(req, "julia") && continue
            s = split(req," ")
            if length(s) == 1  # plain dep
                push!(graph[pkg.name], req)
            elseif s[1][1] == '@' # first term is e.g. @osx
                push!(graph[pkg.name], s[2])
            else # discard version requirements
                push!(graph[pkg.name], s[1])
            end
        end
    end

    return graph
end

#######################################################################
# walk_graph_to_adj_matrix
# Starting from a specific package, walk the directed graph to 
# extract the connected component defined by that package.
# Just returns the size of that component
function walk_graph(graph, root_pkg)
    # Maintain state with a dictionary
    depth = Dict()
    depth[root_pkg] = 0

    cur_depth = 0
    comp_size = 1

    # Keep walking...
    while true
        added_new = false
        for pkg in keys(graph)
            # Is this a package to process at current depth?
            if get(depth, pkg, -1) == cur_depth
                # Look through all requirements of this package
                for req in graph[pkg]
                    # Unprocessed?
                    if get(depth, req, -1) == -1
                        # Add to list to be processed
                        depth[req] = cur_depth + 1
                        added_new = true
                        comp_size += 1
                    end
                end
            end
        end
        # If we didn't find any packages, we're done
        !added_new && break
        # Move to next depth
        cur_depth += 1
    end

    return comp_size
end

#######################################################################

pkgs = MetaTools.get_all_pkg(METAPATH)
graph = build_graph(pkgs)
sizepkg = [(walk_graph(graph, pkg.name),pkg.name) for pkg in pkgs]
sort!(sizepkg,rev=true)
for sz in sizepkg
    sz[1] == 1 && continue
    println(sz[2], "   ", sz[1])
end