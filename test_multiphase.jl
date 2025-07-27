# test_multiphase.jl
using Pkg
Pkg.activate(".")

# Load the modules (no module wrappers needed)
include("src/cnf_parser.jl")
include("src/graph_builder.jl")
include("src/community_detection.jl")
include("src/maxsat_solver.jl")

function run_instance(instance_path::String, label::String)
    println("\n\n🚀 Testing $label")
    println("=" ^ 60)
    
    # Parse the instance
    println("📁 Loading $instance_path ...")
    num_vars, num_clauses, clauses = parse_cnf_file(instance_path)
    println("  Variables: $num_vars")
    println("  Clauses: $num_clauses")
    
    # Build graph and detect communities
    println("\n🕸️  Building clause interaction graph...")
    graph = build_variable_interaction_graph(clauses, num_vars)
    communities = detect_communities(graph)
    println("  Graph edges: $(length(edges(graph)))")
    println("  Communities found: $(length(unique(communities)))")
    println("  Community assignments: $communities")
    
    # Test the new multi-phase approach
    println("\n🎯 Testing Multi-Phase Approach:")
    assignment, score = solve_maxsat_with_communities(clauses, num_vars, communities)
    println("  Final assignment: [truncated] (length $(length(assignment)))")
    println("  Score: $score/$num_clauses clauses satisfied")
    
    # Compare with baseline
    println("\n📊 Performance Comparison:")
    baseline_assignment, baseline_score = solve_maxsat_baseline(clauses, num_vars, num_trials=100)
    baseline_frac = round(baseline_score / num_clauses, digits=2)
    multi_frac = round(score / num_clauses, digits=2)
    println("  Baseline (100 random): $baseline_score/$num_clauses clauses ($baseline_frac)")
    println("  Multi-phase approach:  $score/$num_clauses clauses ($multi_frac)")
    improvement = score - baseline_score
    if improvement > 0
        println("  🎉 Improvement: +$improvement clauses!")
    elseif improvement == 0
        println("  🤝 Tied with baseline")
    else
        println("  📉 Difference: $improvement clauses")
    end
    
    # Test if we found the optimal solution
    if score == num_clauses
        println("\n🏆 OPTIMAL SOLUTION FOUND! All clauses satisfied!")
    else
        println("\n💡 $(num_clauses - score) clauses remain unsatisfied")
    end
end

# Run on small instance
test_small = "instances/test_3var_5clause.cnf"
run_instance(test_small, "Small Test Instance (3 vars, 5 clauses)")

# Run on first five large instances in the specified folder
large_folder = "instances/uuf50.218.1000"
large_files = [
    "uuf50-01.cnf",
    "uuf50-02.cnf",
    "uuf50-03.cnf",
    "uuf50-04.cnf",
    "uuf50-05.cnf"
]
for (i, fname) in enumerate(large_files)
    path = joinpath(large_folder, fname)
    label = "Large Instance: $(fname)"
    run_instance(path, label)
end