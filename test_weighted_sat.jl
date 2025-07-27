#!/usr/bin/env julia

"""
Test weighted community detection on SAT instances.
Compare weighted vs unweighted graph approaches.
"""

using Pkg
using Dates
Pkg.activate(".")

# Get the absolute path to this script's directory
script_dir = dirname(abspath(@__FILE__))

include(joinpath(script_dir, "src", "cnf_parser.jl"))
include(joinpath(script_dir, "src", "graph_builder.jl"))
include(joinpath(script_dir, "src", "community_detection.jl"))
include(joinpath(script_dir, "src", "maxsat_solver.jl"))

function test_weighted_vs_unweighted_instance(filename::String)
    println("\n" * "="^70)
    println("Testing: $filename")
    println("="^70)
    
    # Parse the CNF file
    filepath = joinpath("instances/UUF50.218.1000", filename)
    num_vars, num_clauses, clauses = parse_cnf_file(filepath)
    
    println("Variables: $num_vars, Clauses: $num_clauses")
    
    # Test different conflict thresholds
    for min_conflicts in [1, 2, 3]
        println("\n--- Minimum conflicts threshold: $min_conflicts ---")
        
        # Build unweighted graph
        g_unweighted = build_variable_interaction_graph(clauses, num_vars, weighted=false, min_conflicts=min_conflicts)
        
        # Build weighted graph
        g_weighted = build_variable_interaction_graph(clauses, num_vars, weighted=true, min_conflicts=min_conflicts)
        
        println("Unweighted edges: $(ne(g_unweighted))")
        println("Weighted edges:   $(ne(g_weighted))")
        
        # Community detection on unweighted graph
        communities_unweighted = detect_communities(g_unweighted, seed=42)
        num_communities_unweighted = length(unique(communities_unweighted))
        
        # Community detection on weighted graph
        communities_weighted = weighted_label_propagation_communities(g_weighted, seed=42)
        num_communities_weighted = length(unique(communities_weighted))
        
        println("Communities (unweighted): $num_communities_unweighted")
        println("Communities (weighted):   $num_communities_weighted")
        
        # Analyze community sizes for both
        unweighted_sizes = sort([count(==(c), communities_unweighted) for c in unique(communities_unweighted)], rev=true)
        weighted_sizes = sort([count(==(c), communities_weighted) for c in unique(communities_weighted)], rev=true)
        
        println("Largest unweighted communities: $(unweighted_sizes[1:min(5, length(unweighted_sizes))])")
        println("Largest weighted communities:   $(weighted_sizes[1:min(5, length(weighted_sizes))])")
        
        # Test solver performance (use unweighted communities for fair comparison with existing code)
        assignment_unweighted, score_unweighted = solve_maxsat_with_communities(clauses, num_vars, communities_unweighted)
        assignment_weighted, score_weighted = solve_maxsat_with_communities(clauses, num_vars, communities_weighted)
        baseline_assignment, baseline_score = solve_maxsat_baseline(clauses, num_vars, num_trials=30)
        
        improvement_unweighted = score_unweighted - baseline_score
        improvement_weighted = score_weighted - baseline_score
        
        println("Scores - Baseline: $baseline_score, Unweighted: $score_unweighted ($(improvement_unweighted > 0 ? "+" : "")$improvement_unweighted), Weighted: $score_weighted ($(improvement_weighted > 0 ? "+" : "")$improvement_weighted)")
        
        # Highlight the better approach
        if improvement_weighted > improvement_unweighted
            println("🏆 Weighted approach wins!")
        elseif improvement_unweighted > improvement_weighted
            println("🏆 Unweighted approach wins!")
        else
            println("🤝 Tie!")
        end
    end
end

function main()
    println("Testing Weighted vs Unweighted Community Detection on SAT Instances")
    println("Date: $(Dates.now())")
    
    # Test on a few representative instances
    test_instances = ["uuf50-01.cnf", "uuf50-07.cnf", "uuf50-010.cnf"]  # Different performance characteristics
    
    for filename in test_instances
        try
            test_weighted_vs_unweighted_instance(filename)
        catch e
            println("ERROR testing $filename: $e")
        end
    end
    
    println("\n" * "="^70)
    println("Weighted vs Unweighted testing complete!")
    println("="^70)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
