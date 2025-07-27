#!/usr/bin/env julia

"""
Analyze weight distribution in weighted clause interaction graphs.
"""

using Pkg
using Dates
Pkg.activate(".")

script_dir = dirname(abspath(@__FILE__))
include(joinpath(script_dir, "src", "cnf_parser.jl"))
include(joinpath(script_dir, "src", "graph_builder.jl"))

function analyze_weights(filename::String)
    println("\n" * "="^50)
    println("Weight Analysis: $filename")
    println("="^50)
    
    # Parse the CNF file
    filepath = joinpath("instances/UUF50.218.1000", filename)
    num_vars, num_clauses, clauses = parse_cnf_file(filepath)
    
    # Build weighted graph with min_conflicts = 1 to see all weights
    g_weighted = build_weighted_clause_interaction_graph(clauses, num_vars, min_conflicts=1)
    
    # Collect all edge weights
    weights = Float64[]
    for edge in edges(g_weighted)
        weight = g_weighted.weights[src(edge), dst(edge)]
        push!(weights, weight)
    end
    
    println("Total edges: $(length(weights))")
    println("Weight statistics:")
    println("  Min weight: $(minimum(weights))")
    println("  Max weight: $(maximum(weights))")
    println("  Mean weight: $(round(sum(weights)/length(weights), digits=2))")
    
    # Weight distribution
    weight_counts = Dict{Int, Int}()
    for w in weights
        w_int = Int(w)
        weight_counts[w_int] = get(weight_counts, w_int, 0) + 1
    end
    
    println("Weight distribution:")
    for weight in sort(collect(keys(weight_counts)))
        count = weight_counts[weight]
        percentage = round(100 * count / length(weights), digits=1)
        println("  Weight $weight: $count edges ($percentage%)")
    end
    
    # Analyze how many clauses would be connected at different thresholds
    for threshold in [1, 2, 3, 4, 5]
        edges_at_threshold = sum(w >= threshold for w in weights)
        println("Edges with weight ≥ $threshold: $edges_at_threshold")
    end
end

function main()
    println("Weight Distribution Analysis")
    println("Date: $(Dates.now())")
    
    test_instances = ["uuf50-01.cnf", "uuf50-07.cnf", "uuf50-010.cnf"]
    
    for filename in test_instances
        try
            analyze_weights(filename)
        catch e
            println("ERROR analyzing $filename: $e")
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
