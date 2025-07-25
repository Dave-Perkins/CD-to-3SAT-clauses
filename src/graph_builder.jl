"""
Graph construction from SAT instances.
Different graph representations for community detection.
"""

using Graphs

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
            if conflicts >= 1
                add_edge!(g, i, j)
            end
        end
    end
    
    return g
end
