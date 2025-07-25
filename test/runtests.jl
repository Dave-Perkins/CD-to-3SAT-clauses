using Test
using Pkg
Pkg.activate("..")

# Include our module
include("../src/CommunityMaxSAT.jl")
using .CommunityMaxSAT

@testset "CommunityMaxSAT Tests" begin
    
    @testset "CNF Parser Tests" begin
        # Test basic parsing functionality
        # You would add actual test CNF files here
        
        # Test clause structure analysis
        test_clauses = [[1, -2, 3], [-1, 2], [2, 3, -4]]
        structure = CommunityMaxSAT.analyze_cnf_structure(test_clauses)
        
        @test structure[:clause_count] == 3
        @test Set(structure[:unique_clause_lengths]) == Set([2, 3])
        @test structure[:num_variables] == 4
    end
    
    @testset "Graph Builder Tests" begin
        test_clauses = [[1, -2, 3], [-1, 2], [2, 3, -4]]
        num_vars = 4
        
        # Test variable interaction graph
        g = build_sat_graph(test_clauses, num_vars, graph_type=:variable_interaction)
        @test nv(g) == num_vars
        @test ne(g) >= 0  # Should have some edges
        
        # Test bipartite graph
        bg = build_sat_graph(test_clauses, num_vars, graph_type=:bipartite)
        @test nv(bg) == num_vars + length(test_clauses)
    end
    
    @testset "MAX-SAT Solver Tests" begin
        test_clauses = [[1, -2, 3], [-1, 2], [2, 3, -4]]
        num_vars = 4
        
        # Test random assignment
        assignment = CommunityMaxSAT.random_assignment(num_vars)
        @test length(assignment) == num_vars
        @test all(x isa Bool for x in assignment)
        
        # Test evaluation
        score = CommunityMaxSAT.evaluate_assignment(test_clauses, assignment)
        @test 0 <= score <= length(test_clauses)
        
        # Test baseline solver
        best_assignment, best_score = solve_maxsat_baseline(test_clauses, num_vars, num_trials=10)
        @test length(best_assignment) == num_vars
        @test 0 <= best_score <= length(test_clauses)
    end
end
