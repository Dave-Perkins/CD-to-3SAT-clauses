#!/usr/bin/env julia

using Pkg
Pkg.activate(".")

include("src/graph_builder.jl")

"""
Debug version of build_weighted_clause_interaction_graph with detailed print statements.
"""
function debug_build_weighted_clause_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int; min_conflicts::Int = 1, weight_function::Function = identity)
    println("=== DEBUG: build_weighted_clause_interaction_graph ===")
    println("Input clauses: $clauses")
    println("Number of variables: $num_vars")
    println("Minimum conflicts threshold: $min_conflicts")
    println("Weight function: $weight_function")
    
    num_clauses = length(clauses)
    println("Number of clauses: $num_clauses")
    
    g = SimpleWeightedGraph(num_clauses)
    println("Created SimpleWeightedGraph with $num_clauses vertices")
    
    edge_count = 0
    
    for i in eachindex(clauses)
        for j in (i+1):lastindex(clauses)
            clause1 = clauses[i]
            clause2 = clauses[j]
            
            println("\n--- Checking clauses $i and $j ---")
            println("Clause $i: $clause1")
            println("Clause $j: $clause2")
            
            # Count conflicts: literals in clause1 whose negations are in clause2
            conflicts = 0
            conflict_details = []
            
            for lit1 in clause1
                negation = -lit1
                if negation in clause2
                    conflicts += 1
                    push!(conflict_details, "$lit1 conflicts with $negation")
                end
            end
            
            println("Conflicts found: $conflicts")
            if conflicts > 0
                println("Conflict details: $conflict_details")
            end
            
            # Add weighted edge if conflicts meet minimum threshold
            if conflicts >= min_conflicts
                println("✓ Conflicts ($conflicts) >= threshold ($min_conflicts), adding edge...")
                
                try
                    raw_weight = weight_function(conflicts)
                    println("Raw weight from function: $raw_weight (type: $(typeof(raw_weight)))")
                    
                    weight = Float64(raw_weight)
                    println("Converted weight: $weight")
                    
                    # Validate weight is positive and finite
                    if isfinite(weight) && weight > 0
                        println("Weight is valid (finite and positive)")
                        # Ensure we use the correct add_edge! method for SimpleWeightedGraph
                        success = add_edge!(g, i, j, weight)
                        println("add_edge! result: $success")
                        if success
                            edge_count += 1
                            println("✓ Edge added successfully. Total edges: $edge_count")
                        else
                            println("✗ Failed to add edge")
                        end
                    else
                        println("⚠ Weight is invalid (not finite or not positive), using fallback")
                        # Fallback to conflict count if weight function produces invalid result
                        fallback_weight = Float64(conflicts)
                        println("Fallback weight: $fallback_weight")
                        success = add_edge!(g, i, j, fallback_weight)
                        println("add_edge! (fallback) result: $success")
                        if success
                            edge_count += 1
                            println("✓ Edge added with fallback weight. Total edges: $edge_count")
                        end
                    end
                catch e
                    println("✗ Exception caught: $e")
                    # If weight function fails, use raw conflict count
                    fallback_weight = Float64(conflicts)
                    println("Using fallback weight due to exception: $fallback_weight")
                    success = add_edge!(g, i, j, fallback_weight)
                    println("add_edge! (exception fallback) result: $success")
                    if success
                        edge_count += 1
                        println("✓ Edge added with exception fallback. Total edges: $edge_count")
                    end
                end
            else
                println("✗ Not enough conflicts ($conflicts < $min_conflicts), skipping edge")
            end
        end
    end
    
    println("\n=== FINAL GRAPH SUMMARY ===")
    println("Total vertices: $(nv(g))")
    println("Total edges: $(ne(g))")
    println("Expected edges: $edge_count")
    
    if ne(g) > 0
        println("\nEdge details:")
        for (idx, edge) in enumerate(edges(g))
            println("  Edge $idx: $(src(edge)) -> $(dst(edge)), weight = $(weight(edge))")
        end
    else
        println("No edges in graph")
    end
    
    return g
end

# Test with a small instance
println("Testing with small manual instance...")
test_clauses = [
    [1, 2, 3],      # Clause 1
    [-1, 4, 5],     # Clause 2 (conflicts with clause 1 on literal 1)
    [2, -4, 6],     # Clause 3 (conflicts with clause 2 on literal 4)
    [-2, -3, 7]     # Clause 4 (conflicts with clauses 1 and 3)
]

println("\nTest case 1: Linear weights, min_conflicts=1")
g1 = debug_build_weighted_clause_interaction_graph(test_clauses, 7, min_conflicts=1, weight_function=x -> x)

println("\n" * "="^80)
println("\nTest case 2: Quadratic weights, min_conflicts=2")
g2 = debug_build_weighted_clause_interaction_graph(test_clauses, 7, min_conflicts=2, weight_function=x -> x^2)

println("\n" * "="^80)
println("\nTest case 3: Exponential weights, min_conflicts=1")
g3 = debug_build_weighted_clause_interaction_graph(test_clauses, 7, min_conflicts=1, weight_function=x -> 2.0^x)
