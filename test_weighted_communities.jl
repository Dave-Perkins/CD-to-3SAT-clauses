#!/usr/bin/env julia

"""
Test weighted vs unweighted label propagation community detection.
"""

using Pkg
Pkg.activate(".")

include("src/community_detection.jl")
using Graphs
using SimpleWeightedGraphs

function test_weighted_vs_unweighted()
    println("Testing Weighted vs Unweighted Label Propagation")
    println("=" * "="^50)
    
    # Create a simple test graph
    # Graph structure: 1-2-3   4-5-6
    # With varying edge weights
    
    # Unweighted version
    g_unweighted = SimpleGraph(6)
    add_edge!(g_unweighted, 1, 2)
    add_edge!(g_unweighted, 2, 3)
    add_edge!(g_unweighted, 4, 5)
    add_edge!(g_unweighted, 5, 6)
    add_edge!(g_unweighted, 3, 4)  # Bridge between clusters
    
    println("Unweighted graph:")
    println("Edges: ", edges(g_unweighted))
    
    communities_unweighted = detect_communities(g_unweighted, seed=123)
    println("Communities (unweighted): ", communities_unweighted)
    println("Unique communities: ", length(unique(communities_unweighted)))
    println()
    
    # Weighted version - make the bridge edge very weak
    g_weighted = SimpleWeightedGraph(6)
    add_edge!(g_weighted, 1, 2, 5.0)  # Strong edges within clusters
    add_edge!(g_weighted, 2, 3, 5.0)
    add_edge!(g_weighted, 4, 5, 5.0)
    add_edge!(g_weighted, 5, 6, 5.0)
    add_edge!(g_weighted, 3, 4, 0.1)  # Weak bridge between clusters
    
    println("Weighted graph:")
    println("Edges with weights:")
    for edge in edges(g_weighted)
        println("  $(src(edge)) -- $(dst(edge)): weight $(g_weighted.weights[src(edge), dst(edge)])")
    end
    
    communities_weighted = weighted_label_propagation_communities(g_weighted, seed=123)
    println("Communities (weighted): ", communities_weighted)
    println("Unique communities: ", length(unique(communities_weighted)))
    println()
    
    # Compare results
    println("Comparison:")
    println("Unweighted communities: ", length(unique(communities_unweighted)))
    println("Weighted communities:   ", length(unique(communities_weighted)))
    
    if length(unique(communities_weighted)) > length(unique(communities_unweighted))
        println("✅ Weighted version found more fine-grained communities (as expected with weak bridge)")
    elseif length(unique(communities_weighted)) == length(unique(communities_unweighted))
        println("⚠️  Both versions found the same number of communities")
    else
        println("❌ Weighted version found fewer communities")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_weighted_vs_unweighted()
end
