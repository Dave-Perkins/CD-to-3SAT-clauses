"""
MAX-SAT solvers using community structure.
"""

using Random

"""
    random_assignment(num_vars::Int) -> Vector{Bool}

Generate a random truth assignment for variables 1:num_vars.
"""
function random_assignment(num_vars::Int)
    return rand(Bool, num_vars)
end

"""
    evaluate_assignment(clauses::Vector{Vector{Int}}, assignment::Vector{Bool}) -> Int

Count how many clauses are satisfied by the given assignment.
"""
function evaluate_assignment(clauses::Vector{Vector{Int}}, assignment::Vector{Bool})
    satisfied_count = 0
    
    for clause in clauses
        clause_satisfied = false
        for literal in clause
            variable = abs(literal)
            is_positive = literal > 0
            
            if (is_positive && assignment[variable]) || (!is_positive && !assignment[variable])
                clause_satisfied = true
                break
            end
        end
        
        if clause_satisfied
            satisfied_count += 1
        end
    end
    
    return satisfied_count
end

"""
    community_guided_assignment_from_clauses(clauses::Vector{Vector{Int}}, num_vars::Int, clause_communities::Vector{Int}) -> Vector{Bool}

Generate a truth assignment using clause community structure.
clause_communities[i] is the community ID for clause i.
"""
function community_guided_assignment_from_clauses(clauses::Vector{Vector{Int}}, num_vars::Int, clause_communities::Vector{Int})
    assignment = Vector{Bool}(undef, num_vars)
    
    # Initialize with random assignment
    for i in 1:num_vars
        assignment[i] = rand(Bool)
    end
    
    # Get unique communities
    unique_communities = unique(clause_communities)
    
    # For each community of clauses, try to satisfy as many as possible
    for community_id in unique_communities
        community_clause_indices = findall(x -> x == community_id, clause_communities)
        community_clauses = [clauses[i] for i in community_clause_indices]
        
        # Collect all variables involved in this community's clauses
        community_variables = Set{Int}()
        for clause in community_clauses
            for literal in clause
                push!(community_variables, abs(literal))
            end
        end
        community_variables = collect(community_variables)
        
        # Try to find a good assignment for these variables
        # Simple greedy approach: for each variable, try both true/false and pick better
        for var in community_variables
            # Try setting variable to true
            assignment[var] = true
            score_true = sum(is_clause_satisfied(clause, assignment) for clause in community_clauses)
            
            # Try setting variable to false
            assignment[var] = false
            score_false = sum(is_clause_satisfied(clause, assignment) for clause in community_clauses)
            
            # Keep the better assignment
            assignment[var] = score_true >= score_false
        end
    end
    
    return assignment
end

"""
    is_clause_satisfied(clause::Vector{Int}, assignment::Vector{Bool}) -> Bool

Check if a clause is satisfied by the given assignment.
"""
function is_clause_satisfied(clause::Vector{Int}, assignment::Vector{Bool})
    for literal in clause
        variable = abs(literal)
        is_positive = literal > 0
        
        if (is_positive && assignment[variable]) || (!is_positive && !assignment[variable])
            return true
        end
    end
    return false
end

"""
    solve_maxsat_with_communities(clauses::Vector{Vector{Int}}, num_vars::Int, clause_communities::Vector{Int}) -> (Vector{Bool}, Int)

Solve MAX-SAT using clause community structure. Returns (assignment, num_satisfied_clauses).
clause_communities[i] is the community ID for clause i.
"""
function solve_maxsat_with_communities(clauses::Vector{Vector{Int}}, num_vars::Int, clause_communities::Vector{Int})
    # Try multiple strategies and return the best
    
    # Strategy 1: Random assignment
    random_assign = random_assignment(num_vars)
    random_score = evaluate_assignment(clauses, random_assign)
    
    # Strategy 2: Community-guided assignment using clause communities
    community_assign = community_guided_assignment_from_clauses(clauses, num_vars, clause_communities)
    community_score = evaluate_assignment(clauses, community_assign)
    
    # Strategy 3: Try a few more random assignments
    best_assignment = random_assign
    best_score = random_score
    
    for _ in 1:10
        test_assign = random_assignment(num_vars)
        test_score = evaluate_assignment(clauses, test_assign)
        if test_score > best_score
            best_assignment = test_assign
            best_score = test_score
        end
    end
    
    # Compare community-guided with best random
    if community_score > best_score
        return community_assign, community_score
    else
        return best_assignment, best_score
    end
end

"""
    solve_maxsat_baseline(clauses::Vector{Vector{Int}}, num_vars::Int; num_trials::Int = 100) -> (Vector{Bool}, Int)

Baseline MAX-SAT solver using random assignments.
"""
function solve_maxsat_baseline(clauses::Vector{Vector{Int}}, num_vars::Int; num_trials::Int = 100)
    best_assignment = random_assignment(num_vars)
    best_score = evaluate_assignment(clauses, best_assignment)
    
    for _ in 1:num_trials
        assignment = random_assignment(num_vars)
        score = evaluate_assignment(clauses, assignment)
        if score > best_score
            best_assignment = assignment
            best_score = score
        end
    end
    
    return best_assignment, best_score
end
