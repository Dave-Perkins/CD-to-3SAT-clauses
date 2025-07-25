module CommunityMaxSAT

using Graphs
using Random
using Statistics

# Export main functions that users will call
export parse_cnf_file, build_variable_interaction_graph, detect_communities, solve_maxsat_with_communities, solve_maxsat_baseline

# Include submodules
include("cnf_parser.jl")
include("graph_builder.jl")
include("community_detection.jl")
include("maxsat_solver.jl")

end # module
