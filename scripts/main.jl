#!/usr/bin/env julia

"""
Main script for Community-based MAX-SAT solving.

This script demonstrates the community detection approach to MAX-SAT solving
using the CommunityMaxSAT package.
"""

# Import our module
using Pkg
Pkg.activate(".")  # Activate the current project environment

# Import our custom module
include("../src/CommunityMaxSAT.jl")
using .CommunityMaxSAT
using Graphs  # For nv(), ne() functions

function main()
    println("Community-based MAX-3SAT Solver")
    println("=" ^ 40)
    
    # Default instance file (adjust path as needed)
    instance_file = "../instances/test_3var_5clause.cnf"
    
    if !isfile(instance_file)
        println("Error: Instance file not found: $instance_file")
        println("Please check the path or run from the scripts/ directory")
        return
    end
    
    # Parse the CNF instance
    println("📁 Parsing CNF file: $instance_file")
    num_vars, num_clauses, clauses = parse_cnf_file(instance_file)
    
    println("Variables: $num_vars")
    println("Clauses: $num_clauses")
    
    # Analyze structure
    structure = CommunityMaxSAT.analyze_cnf_structure(clauses)
    println("Clause lengths: $(structure[:unique_clause_lengths])")
    
    # Expected bounds
    expected_random = num_clauses * (7/8)
    expected_best = num_clauses * (8/9)
    println("\n📊 Theoretical bounds:")
    println("Random assignment (7/8): $(round(expected_random, digits=1)) clauses")
    println("Best known (8/9): $(round(expected_best, digits=1)) clauses")
    
    # Build graph representation
    println("\n🔗 Building clause conflict graph...")
    graph = build_variable_interaction_graph(clauses, num_vars)
    println("Graph vertices: $(nv(graph)), edges: $(ne(graph))")
    
    # Detect communities
    println("\n🏘️  Detecting communities...")
    communities = detect_communities(graph)
    unique_communities = unique(communities)
    println("Found $(length(unique_communities)) communities")
    
    # Show community distribution
    for community_id in unique_communities
        community_size = count(x -> x == community_id, communities)
        println("  Community $community_id: $community_size clauses")
    end
    
    # Solve using baseline (random assignment)
    println("\n🎲 Baseline solver (random assignment)...")
    baseline_assignment, baseline_score = solve_maxsat_baseline(clauses, num_vars, num_trials=1000)
    println("Baseline score: $baseline_score / $num_clauses ($(round(baseline_score/num_clauses*100, digits=1))%)")
    
    # Solve using community-guided approach
    println("\n🏘️  Community-guided solver...")
    community_assignment, community_score = solve_maxsat_with_communities(clauses, num_vars, communities)
    println("Community score: $community_score / $num_clauses ($(round(community_score/num_clauses*100, digits=1))%)")
    
    # Compare results
    println("\n📈 Results Summary:")
    println("Baseline (random): $baseline_score clauses")
    println("Community-guided:  $community_score clauses")
    
    improvement = community_score - baseline_score
    if improvement > 0
        println("✅ Community approach improved by $improvement clauses!")
    elseif improvement == 0
        println("➡️  Community approach matched baseline")
    else
        println("❌ Community approach was $(-improvement) clauses worse")
    end
    
    println("\n🎯 Performance vs theoretical bounds:")
    println("Random bound (191.0): baseline=$(baseline_score), community=$(community_score)")
    println("Best bound (193.8): baseline=$(baseline_score), community=$(community_score)")
end

# Run the main function
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
