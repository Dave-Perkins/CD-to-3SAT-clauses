"""
Graph construction from SAT instances.
Different graph representations for community detection.
"""

using Graphs
using SimpleWeightedGraphs

"""
    build_variable_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int) -> SimpleGraph

Build a graph where vertices represent clauses and edges connect clauses 
that have conflicts (at least two literals in one clause have their negations in the other).
"""
function build_variable_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int)
    num_clauses = length(clauses)
    g = SimpleGraph(num_clauses)
    
    for i in eachindex(clauses)
        for j in (i+1):lastindex(clauses)
            clause1 = clauses[i]
            clause2 = clauses[j]
            
            # Count conflicts: literals in clause1 whose negations are in clause2
            conflicts = 0
            for lit1 in clause1
                negation = -lit1
                if negation in clause2
                    conflicts += 1
                end
            end
            
            # Add edge if at least 2 conflicts
            if conflicts >= 2
                add_edge!(g, i, j)
            end
        end
    end
    
    return g
end

"""
    build_weighted_clause_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int; min_conflicts::Int = 1, weight_function::Function = identity) -> SimpleWeightedGraph

Build a weighted graph where vertices represent clauses and edge weights represent the number of conflicts.
Conflicts occur when literals in one clause have their negations in another clause.

Parameters:
- clauses: Vector of clauses (each clause is a vector of literals)
- num_vars: Number of variables (currently unused but kept for API consistency)
- min_conflicts: Minimum number of conflicts required to create an edge (default: 1)
- weight_function: Function to transform conflict count to edge weight (default: identity)
                  Examples: identity, x->x^2, x->2^x, x->log(x+1)

Returns a SimpleWeightedGraph where edge weights = weight_function(conflict_count).
"""
function build_weighted_clause_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int; min_conflicts::Int = 1, weight_function::Function = identity, debug::Bool = false)
    if debug
        println("=== DEBUG: build_weighted_clause_interaction_graph ===")
        println("Input: $(length(clauses)) clauses, $num_vars variables, min_conflicts=$min_conflicts")
    end
    
    num_clauses = length(clauses)
    g = SimpleWeightedGraph(num_clauses)
    
    if debug
        println("Created SimpleWeightedGraph with $num_clauses vertices")
    end
    
    edge_count = 0
    
    for i in eachindex(clauses)
        for j in (i+1):lastindex(clauses)
            clause1 = clauses[i]
            clause2 = clauses[j]
            
            if debug && (i <= 3 || j <= 3)  # Only show first few for brevity
                println("\nChecking clauses $i and $j: $clause1 vs $clause2")
            end
            
            # Count conflicts: literals in clause1 whose negations are in clause2
            conflicts = 0
            for lit1 in clause1
                negation = -lit1
                if negation in clause2
                    conflicts += 1
                end
            end
            
            # Add weighted edge if conflicts meet minimum threshold
            if conflicts >= min_conflicts
                if debug && (i <= 3 || j <= 3)
                    println("  Adding edge: $conflicts conflicts >= $min_conflicts threshold")
                end
                
                try
                    raw_weight = weight_function(conflicts)
                    weight::Float64 = Float64(raw_weight)
                    
                    if debug && (i <= 3 || j <= 3)
                        println("  Weight: $conflicts -> $raw_weight -> $weight")
                    end
                    
                    # Validate weight is positive and finite
                    if isfinite(weight) && weight > 0
                        # Ensure we use the correct add_edge! method for SimpleWeightedGraph
                        success = add_edge!(g::SimpleWeightedGraph, i::Int, j::Int, weight::Float64)::Bool
                        if success
                            edge_count += 1
                        end
                        
                        if debug && (i <= 3 || j <= 3)
                            println("  Edge added: $success (total edges: $edge_count)")
                        end
                    else
                        # Fallback to conflict count if weight function produces invalid result
                        fallback_weight::Float64 = Float64(conflicts)
                        success = add_edge!(g::SimpleWeightedGraph, i::Int, j::Int, fallback_weight::Float64)::Bool
                        if success
                            edge_count += 1
                        end
                        
                        if debug
                            println("  Used fallback weight: $fallback_weight (success: $success)")
                        end
                    end
                catch e
                    # If weight function fails, use raw conflict count
                    fallback_weight::Float64 = Float64(conflicts)
                    success = add_edge!(g::SimpleWeightedGraph, i::Int, j::Int, fallback_weight::Float64)::Bool
                    if success
                        edge_count += 1
                    end
                    
                    if debug
                        println("  Exception caught: $e, used fallback: $fallback_weight")
                    end
                end
            else
                if debug && (i <= 3 || j <= 3) && conflicts > 0
                    println("  Skipping edge: $conflicts conflicts < $min_conflicts threshold")
                end
            end
        end
    end
    
    if debug
        println("\n=== FINAL SUMMARY ===")
        println("Graph: $(nv(g)) vertices, $(ne(g)) edges")
        if ne(g) > 0
            weights = [weight(e) for e in edges(g)]
            println("Weight range: $(minimum(weights)) - $(maximum(weights))")
        end
    end

    return g
end

"""
    build_variable_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int; weighted::Bool = false, min_conflicts::Int = 2, weight_function::Function = identity) -> Union{SimpleGraph, SimpleWeightedGraph}

Unified interface for building clause interaction graphs.

Parameters:
- clauses: Vector of clauses (each clause is a vector of literals)
- num_vars: Number of variables
- weighted: If true, returns weighted graph with conflict counts as weights; if false, returns unweighted graph
- min_conflicts: Minimum number of conflicts required to create an edge
- weight_function: Function to transform conflict count to edge weight (only used if weighted=true)

Returns either a SimpleGraph (if weighted=false) or SimpleWeightedGraph (if weighted=true).
"""
function build_variable_interaction_graph(clauses::Vector{Vector{Int}}, num_vars::Int; weighted::Bool = false, min_conflicts::Int = 2, weight_function::Function = identity, debug::Bool = false)
    if weighted
        return build_weighted_clause_interaction_graph(clauses, num_vars, min_conflicts=min_conflicts, weight_function=weight_function, debug=debug)
    else
        # Keep the existing unweighted implementation
        num_clauses = length(clauses)
        g = SimpleGraph(num_clauses)
        
        for i in eachindex(clauses)
            for j in (i+1):lastindex(clauses)
                clause1 = clauses[i]
                clause2 = clauses[j]
                
                # Count conflicts: literals in clause1 whose negations are in clause2
                conflicts = 0
                for lit1 in clause1
                    negation = -lit1
                    if negation in clause2
                        conflicts += 1
                    end
                end
                
                # Add edge if at least min_conflicts conflicts
                if conflicts >= min_conflicts
                    add_edge!(g, i, j)
                end
            end
        end
        
        return g
    end
end
