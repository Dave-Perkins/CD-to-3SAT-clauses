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

Solve MAX-SAT using clause community structure with a sophisticated multi-phase approach:

MULTI-PHASE APPROACH:
1. **Community-Priority Assignment**: Start with community-guided heuristic, prioritizing larger communities
2. **Local Search per Community**: Apply hill-climbing within each community separately
3. **Global Refinement**: Use iterative improvement across all variables
4. **Variable Ordering**: Prioritize variables that appear in many unsatisfied clauses

Returns (assignment, num_satisfied_clauses).
clause_communities[i] is the community ID for clause i.
"""
function solve_maxsat_with_communities(clauses::Vector{Vector{Int}}, num_vars::Int, clause_communities::Vector{Int})
    # Phase 1: Community-Priority Assignment
    assignment = community_priority_assignment(clauses, num_vars, clause_communities)
    
    # Phase 2: Local Search per Community
    assignment = local_search_per_community(clauses, assignment, clause_communities)
    
    # Phase 3: Global Refinement
    assignment = global_refinement_search(clauses, assignment)
    
    # Evaluate final assignment
    final_score = evaluate_assignment(clauses, assignment)
    
    return assignment, final_score
end

"""
    community_priority_assignment(clauses, num_vars, clause_communities) -> Vector{Bool}

Phase 1: Initialize assignment by processing communities in order of size (largest first).
"""
function community_priority_assignment(clauses::Vector{Vector{Int}}, num_vars::Int, clause_communities::Vector{Int})
    assignment = Vector{Bool}(undef, num_vars)
    
    # Initialize with random assignment
    for i in 1:num_vars
        assignment[i] = rand(Bool)
    end
    
    # Get communities sorted by size (largest first)
    unique_communities = unique(clause_communities)
    community_sizes = [(community_id, count(==(community_id), clause_communities)) 
                      for community_id in unique_communities]
    sort!(community_sizes, by=x->x[2], rev=true)  # Sort by size, largest first
    
    # Process communities in priority order
    for (community_id, size) in community_sizes
        community_clause_indices = findall(x -> x == community_id, clause_communities)
        community_clauses = [clauses[i] for i in community_clause_indices]
        
        # Collect variables in this community
        community_variables = Set{Int}()
        for clause in community_clauses
            for literal in clause
                push!(community_variables, abs(literal))
            end
        end
        community_variables = collect(community_variables)
        
        # Greedy assignment for this community's variables
        for var in community_variables
            # Try both values and pick the better one
            assignment[var] = true
            score_true = sum(is_clause_satisfied(clause, assignment) for clause in community_clauses)
            
            assignment[var] = false
            score_false = sum(is_clause_satisfied(clause, assignment) for clause in community_clauses)
            
            assignment[var] = score_true >= score_false
        end
    end
    
    return assignment
end

"""
    local_search_per_community(clauses, assignment, clause_communities) -> Vector{Bool}

Phase 2: Apply hill-climbing search within each community separately.
"""
function local_search_per_community(clauses::Vector{Vector{Int}}, assignment::Vector{Bool}, clause_communities::Vector{Int})
    assignment = copy(assignment)
    unique_communities = unique(clause_communities)
    
    for community_id in unique_communities
        community_clause_indices = findall(x -> x == community_id, clause_communities)
        community_clauses = [clauses[i] for i in community_clause_indices]
        
        # Get variables in this community
        community_variables = Set{Int}()
        for clause in community_clauses
            for literal in clause
                push!(community_variables, abs(literal))
            end
        end
        community_variables = collect(community_variables)
        
        # Hill climbing within this community
        improved = true
        max_iterations = 50
        iteration = 0
        
        while improved && iteration < max_iterations
            improved = false
            iteration += 1
            
            # Try flipping each variable in this community
            for var in community_variables
                current_score = sum(is_clause_satisfied(clause, assignment) for clause in community_clauses)
                
                # Flip variable and check if it improves
                assignment[var] = !assignment[var]
                new_score = sum(is_clause_satisfied(clause, assignment) for clause in community_clauses)
                
                if new_score > current_score
                    improved = true  # Keep the flip
                else
                    assignment[var] = !assignment[var]  # Revert the flip
                end
            end
        end
    end
    
    return assignment
end

"""
    global_refinement_search(clauses, assignment) -> Vector{Bool}

Phase 3: Global refinement using variable frequency-based ordering.
"""
function global_refinement_search(clauses::Vector{Vector{Int}}, assignment::Vector{Bool})
    assignment = copy(assignment)
    num_vars = length(assignment)
    max_iterations = 100
    
    for iteration in 1:max_iterations
        # Find unsatisfied clauses
        unsatisfied_clauses = []
        for (i, clause) in enumerate(clauses)
            if !is_clause_satisfied(clause, assignment)
                push!(unsatisfied_clauses, clause)
            end
        end
        
        if isempty(unsatisfied_clauses)
            break  # All clauses satisfied!
        end
        
        # Count variable frequency in unsatisfied clauses
        var_frequency = zeros(Int, num_vars)
        for clause in unsatisfied_clauses
            for literal in clause
                var = abs(literal)
                var_frequency[var] += 1
            end
        end
        
        # Try flipping variables in order of frequency (most frequent first)
        var_order = sortperm(var_frequency, rev=true)
        improved = false
        
        for var in var_order
            if var_frequency[var] == 0
                break  # No more variables in unsatisfied clauses
            end
            
            current_score = evaluate_assignment(clauses, assignment)
            
            # Try flipping this variable
            assignment[var] = !assignment[var]
            new_score = evaluate_assignment(clauses, assignment)
            
            if new_score > current_score
                improved = true
                break  # Keep this improvement and continue
            else
                assignment[var] = !assignment[var]  # Revert
            end
        end
        
        if !improved
            break  # No improvement found, terminate
        end
    end
    
    return assignment
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
