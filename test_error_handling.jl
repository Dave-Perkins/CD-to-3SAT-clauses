#!/usr/bin/env julia

"""
Test the fixed error handling in weighted graph builder.
"""

using Pkg
Pkg.activate(".")

include("src/cnf_parser.jl")
include("src/graph_builder.jl")

function test_weight_function_robustness()
    println("Testing Weight Function Error Handling")
    println("="^50)
    
    # Simple test clauses
    clauses = [[1, 2, 3], [-1, -2, 4], [1, -3, 5], [-1, 2, -4]]
    num_vars = 5
    
    # Test various problematic weight functions
    test_cases = [
        ("Normal Linear", x -> x, "Should work normally"),
        ("Returns Infinity", x -> x == 2 ? Inf : x, "Should fallback to conflict count for Inf"),
        ("Returns Negative", x -> -x, "Should fallback to conflict count for negative"),
        ("Returns NaN", x -> x == 2 ? NaN : x, "Should fallback to conflict count for NaN"),
        ("Throws Error", x -> x == 2 ? error("test") : x, "Should catch error and fallback"),
        ("Returns String", x -> "invalid", "Should catch conversion error and fallback"),
        ("Returns Zero", x -> 0.0, "Should fallback for zero weight"),
        ("Very Large", x -> 10.0^100, "Should work with large finite numbers")
    ]
    
    for (name, weight_func, description) in test_cases
        println("\nTesting: $name")
        println("  Expected: $description")
        
        try
            g = build_weighted_clause_interaction_graph(clauses, num_vars, 
                                                       min_conflicts=1, 
                                                       weight_function=weight_func)
            
            num_edges = ne(g)
            if num_edges > 0
                # Get some sample weights
                weights = [g.weights[src(e), dst(e)] for e in edges(g)]
                min_weight = minimum(weights)
                max_weight = maximum(weights)
                
                println("  ✅ Success: $num_edges edges, weights range $(round(min_weight, digits=2)) - $(round(max_weight, digits=2))")
                
                # Check that all weights are positive and finite
                all_valid = all(w > 0 && isfinite(w) for w in weights)
                if all_valid
                    println("     All weights are positive and finite ✓")
                else
                    println("     ⚠️  Some weights are invalid!")
                end
            else
                println("  ✅ Success: No edges created (as expected)")
            end
            
        catch e
            println("  ❌ Unexpected error: $e")
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_weight_function_robustness()
end
