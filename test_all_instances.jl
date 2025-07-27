#!/usr/bin/env julia

"""
Test all 10 SAT instances to see community detection results.
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

function test_instance(filename::String)
    println("\n" * "="^60)
    println("Testing: $filename")
    println("="^60)
    
    # Parse the CNF file
    filepath = joinpath("instances/UUF50.218.1000", filename)
    num_vars, num_clauses, clauses = parse_cnf_file(filepath)
    
    println("Variables: $num_vars")
    println("Clauses: $(length(clauses))")
    
    # Build the clause interaction graph
    graph = build_variable_interaction_graph(clauses, num_vars)
    println("Graph edges: $(ne(graph))")
    
    # Run community detection
    communities = detect_communities(graph)
    num_communities = length(unique(communities))
    println("Communities found: $num_communities")
    
    community_counts = Dict{Int, Int}()
    for comm in communities
        community_counts[comm] = get(community_counts, comm, 0) + 1
    end
    
    println("Community sizes: $(sort(collect(values(community_counts)), rev=true))")
    
    # Test the solver
    assignment, score = solve_maxsat_with_communities(clauses, num_vars, communities)
    baseline_assignment, baseline_score = solve_maxsat_baseline(clauses, num_vars, num_trials=50)
    improvement = score - baseline_score
    
    println("Community-guided score: $score/$(length(clauses))")
    println("Baseline score: $baseline_score/$(length(clauses))")
    println("Improvement: $(improvement > 0 ? "+" : "")$improvement clauses")
end

function main()
    println("Testing all 10 SAT instances for community detection")
    println("Date: $(Dates.now())")
    
    # Get all .cnf files in the instances directory
    instance_dir = "instances/UUF50.218.1000"
    cnf_files = filter(f -> endswith(f, ".cnf"), readdir(instance_dir))
    sort!(cnf_files)  # Sort to get them in order
    
    println("\nFound $(length(cnf_files)) instances:")
    for (i, file) in enumerate(cnf_files)
        println("  $i. $file")
    end
    
    # Test each instance
    for filename in cnf_files
        try
            test_instance(filename)
        catch e
            println("ERROR testing $filename: $e")
        end
    end
    
    println("\n" * "="^60)
    println("Testing complete!")
    println("="^60)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
