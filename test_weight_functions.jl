#!/usr/bin/env julia

"""
Test different weight functions for weighted community detection.
"""

using Pkg
using Dates
Pkg.activate(".")

script_dir = dirname(abspath(@__FILE__))
include(joinpath(script_dir, "src", "cnf_parser.jl"))
include(joinpath(script_dir, "src", "graph_builder.jl"))
include(joinpath(script_dir, "src", "community_detection.jl"))
include(joinpath(script_dir, "src", "maxsat_solver.jl"))

function test_weight_functions(filename::String)
    println("\n" * "="^60)
    println("Testing Weight Functions: $filename")
    println("="^60)
    
    # Parse the CNF file
    filepath = joinpath("instances/UUF50.218.1000", filename)
    num_vars, num_clauses, clauses = parse_cnf_file(filepath)
    
    println("Variables: $num_vars, Clauses: $num_clauses")
    
    # Define different weight functions
    weight_functions = [
        ("Linear", x -> x),              # Default: weight = conflicts
        ("Quadratic", x -> x^2),         # Emphasize higher conflicts more
        ("Exponential", x -> 2.0^x),     # Strong emphasis on higher conflicts
        ("Cubic", x -> x^3),             # Very strong emphasis
        ("Log", x -> log(x + 1))         # De-emphasize differences
    ]
    
    # Test at threshold=2 (most interesting range based on our analysis)
    min_conflicts = 2
    println("\nUsing min_conflicts = $min_conflicts")
    
    # Get baseline performance
    g_unweighted = build_variable_interaction_graph(clauses, num_vars, weighted=false, min_conflicts=min_conflicts)
    communities_unweighted = detect_communities(g_unweighted, seed=42)
    assignment_unweighted, score_unweighted = solve_maxsat_with_communities(clauses, num_vars, communities_unweighted)
    baseline_assignment, baseline_score = solve_maxsat_baseline(clauses, num_vars, num_trials=30)
    
    println("\nBaseline Results:")
    println("  Edges: $(ne(g_unweighted))")
    println("  Communities: $(length(unique(communities_unweighted)))")
    println("  Score: $score_unweighted (baseline: $baseline_score, improvement: $(score_unweighted - baseline_score))")
    
    println("\nWeight Function Comparison:")
    println("-" * "-"^50)
    
    best_score = score_unweighted
    best_function = "Unweighted"
    
    for (name, weight_func) in weight_functions
        try
            # Build weighted graph with this weight function
            g_weighted = build_variable_interaction_graph(clauses, num_vars, 
                                                         weighted=true, 
                                                         min_conflicts=min_conflicts, 
                                                         weight_function=weight_func)
            
            # Community detection
            communities_weighted = weighted_label_propagation_communities(g_weighted, seed=42)
            
            # Solver performance
            assignment_weighted, score_weighted = solve_maxsat_with_communities(clauses, num_vars, communities_weighted)
            improvement = score_weighted - baseline_score
            
            # Analyze weights
            weights = [g_weighted.weights[src(e), dst(e)] for e in edges(g_weighted)]
            min_weight = minimum(weights)
            max_weight = maximum(weights)
            
            println("$name:")
            println("  Communities: $(length(unique(communities_weighted)))")
            println("  Weight range: $(round(min_weight, digits=2)) - $(round(max_weight, digits=2))")
            println("  Score: $score_weighted (improvement: $(improvement > 0 ? "+" : "")$improvement)")
            
            if score_weighted > best_score
                best_score = score_weighted
                best_function = name
            end
            
        catch e
            println("$name: ERROR - $e")
        end
    end
    
    println("\n🏆 Best approach: $best_function (score: $best_score)")
end

function main()
    println("Testing Different Weight Functions for Community Detection")
    println("Date: $(Dates.now())")
    
    # Test on instances with different characteristics
    test_instances = ["uuf50-01.cnf", "uuf50-07.cnf"]  # Best and representative instances
    
    for filename in test_instances
        try
            test_weight_functions(filename)
        catch e
            println("ERROR testing $filename: $e")
        end
    end
    
    println("\n" * "="^60)
    println("Weight function testing complete!")
    println("="^60)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
