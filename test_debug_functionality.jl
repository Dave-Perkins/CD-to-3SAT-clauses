#!/usr/bin/env julia

using Pkg
Pkg.activate(".")

include("src/cnf_parser.jl")
include("src/graph_builder.jl")

println("Testing debug functionality with real SAT instance...")

# Load a small SAT instance
num_vars, num_clauses, clauses = parse_cnf_file("instances/UUF50.218.1000/uuf50-01.cnf")

println("Loaded instance: $num_vars variables, $num_clauses clauses")
println("First 5 clauses: $(clauses[1:5])")

println("\n" * "="^60)
println("Testing with debug=true, linear weights, min_conflicts=2")
println("="^60)

# Test with debug enabled - this will show detailed output for first few clause pairs
g_debug = build_variable_interaction_graph(clauses, num_vars, 
                                         weighted=true, 
                                         min_conflicts=2, 
                                         weight_function=x -> x,
                                         debug=true)

println("\n" * "="^60)
println("Testing with debug=false for comparison")
println("="^60)

# Test without debug for comparison
g_normal = build_variable_interaction_graph(clauses, num_vars, 
                                          weighted=true, 
                                          min_conflicts=2, 
                                          weight_function=x -> x^2,
                                          debug=false)

println("Normal run: $(nv(g_normal)) vertices, $(ne(g_normal)) edges")

# Verify they have same structure
println("\nBoth graphs have same structure: $(nv(g_debug) == nv(g_normal) && ne(g_debug) == ne(g_normal))")
