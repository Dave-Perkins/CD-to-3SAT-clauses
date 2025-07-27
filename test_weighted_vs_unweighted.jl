#!/usr/bin/env julia

using Pkg
Pkg.activate(".")

include("src/cnf_parser.jl")
include("src/graph_builder.jl")
include("src/community_detection.jl")

"""
Test weighted community detection with different weight functions.
"""
function test_weighted_vs_unweighted()
    println("Testing weighted vs unweighted community detection")
    println("=" ^ 60)
    
    # Load a test instance
    instance_file = "instances/UUF50.218.1000/uuf50-01.cnf"
    num_vars, num_clauses, clauses = parse_cnf_file(instance_file)
    
    println("Instance: $(basename(instance_file))")
    println("Variables: $num_vars, Clauses: $num_clauses")
    println()
    
    # Test different configurations
    configs = [
        ("Unweighted (thresh=1)", false, 1, identity),
        ("Unweighted (thresh=2)", false, 2, identity),
        ("Linear weights (thresh=1)", true, 1, x -> x),
        ("Quadratic weights (thresh=1)", true, 1, x -> x^2),
        ("Linear weights (thresh=2)", true, 2, x -> x),
        ("Quadratic weights (thresh=2)", true, 2, x -> x^2)
    ]
    
    results = []
    
    for (name, weighted, min_conflicts, weight_func) in configs
        println("Testing: $name")
        println("-" ^ 40)
        
        # Build graph
        if weighted
            g = build_variable_interaction_graph(clauses, num_vars, 
                                                weighted=true, 
                                                min_conflicts=min_conflicts, 
                                                weight_function=weight_func)
            communities = weighted_label_propagation_communities(g)
        else
            g = build_variable_interaction_graph(clauses, num_vars, 
                                                weighted=false, 
                                                min_conflicts=min_conflicts)
            communities = label_propagation_communities(g)
        end
        
        # Calculate statistics
        num_communities = length(communities)
        community_sizes = [length(c) for c in communities]
        
        graph_stats = (
            vertices = nv(g),
            edges = ne(g),
            density = ne(g) / (nv(g) * (nv(g) - 1) / 2)
        )
        
        community_stats = if length(community_sizes) > 0
            (
                count = num_communities,
                largest = maximum(community_sizes),
                smallest = minimum(community_sizes),
                mean_size = round(sum(community_sizes) / length(community_sizes), digits=2)
            )
        else
            (count = 0, largest = 0, smallest = 0, mean_size = 0.0)
        end
        
        # Show edge weight statistics for weighted graphs
        if weighted && ne(g) > 0
            weights = [weight(e) for e in edges(g)]
            weight_stats = (
                min = minimum(weights),
                max = maximum(weights),
                mean = round(sum(weights) / length(weights), digits=2)
            )
            println("Weight stats: min=$(weight_stats.min), max=$(weight_stats.max), mean=$(weight_stats.mean)")
        end
        
        println("Graph: $(graph_stats.vertices) vertices, $(graph_stats.edges) edges")
        println("Communities: $(community_stats.count) (largest: $(community_stats.largest), mean size: $(community_stats.mean_size))")
        
        push!(results, (name, graph_stats, community_stats))
        println()
    end
    
    # Summary comparison
    println("Summary Comparison:")
    println("=" ^ 60)
    for (name, graph_stats, community_stats) in results
        println("$name: $(community_stats.count) communities, largest=$(community_stats.largest)")
    end
    
    return results
end

# Run the test
if abspath(PROGRAM_FILE) == @__FILE__
    test_weighted_vs_unweighted()
end
