#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################
# Package ecosystem graph example
# Builds dependency graphs of all or parts of the package ecosystem
# and uses GraphLayout.jl and Compose.jl to plot them.
#######################################################################

using PackageEvaluator
using GraphLayout

# The location of METADATA - can change if needed
const METAPATH = Pkg.dir("METADATA")

#######################################################################
# build_graph
# Walk through all packages in METADATA and assemble a representation
# of the dependency graph in adjacency list format.
function build_graph()
    graph = Dict()
    pkgs = MetaTools.get_all_pkg(METAPATH)

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
# extract the connected component defined by that package. Returns an
# adjacency matrix for that component, and the names of the packages.
# Walk is breadth-first-ish
function walk_graph_to_adj_matrix(graph, root_pkg)
    # Maintain state with a dictionary
    depth = Dict()
    depth[root_pkg] = 0
    pkg_to_index = Dict()
    pkg_to_index[root_pkg] = 1
    index_to_pkg = Dict()
    index_to_pkg[1] = root_pkg

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
                        pkg_to_index[req] = comp_size
                        index_to_pkg[comp_size] = req
                    end
                end
            end
        end
        # If we didn't find any packages, we're done
        !added_new && break
        # Move to next depth
        cur_depth += 1
    end

    # We now have the component, turn into an adjacency matrix
    adj_matrix = zeros(Int, comp_size, comp_size)
    node_labels = [index_to_pkg[i] for i in 1:comp_size]
    for row = 1:comp_size
        for req in graph[index_to_pkg[row]]
            col = pkg_to_index[req]
            adj_matrix[row,col] = 1
        end
    end

    return adj_matrix, node_labels
end

#######################################################################
# plot_component
# Extract the connected component from the METADATA dependency graph
# and plot it.
function plot_component(root_pkg)
    graph = build_graph()
    adj_matrix, labels = walk_graph_to_adj_matrix(graph, root_pkg)
    loc_x, loc_y = layout_spring_adj(adj_matrix, C=1.0)
    draw_layout_adj(adj_matrix, loc_x, loc_y, labels=labels, filename="$(root_pkg).svg")
end



plot_component(length(ARGS) == 0 ? "Gadfly" : ARGS[1])