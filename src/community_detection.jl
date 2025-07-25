"""
Community detection algorithms for SAT graphs using label propagation.
"""

using Graphs
using Random

"""
    label_propagation_communities(g::SimpleGraph; max_iterations::Int = 100, seed::Int = 42) -> Vector{Int}

Detect communities using the label propagation algorithm.

Algorithm:
1. Initialize each vertex with a unique label (community ID)
2. Iteratively update each vertex's label to the most frequent label among its neighbors
3. Stop when labels converge or max iterations reached

Returns a vector where communities[i] is the community ID for vertex i.
"""
function label_propagation_communities(g::SimpleGraph; max_iterations::Int = 100, seed::Int = 42)
    Random.seed!(seed)
    n = nv(g)
    
    # Handle edge cases
    if n == 0
        return Int[]
    elseif n == 1
        return [1]
    end
    
    # Initialize each vertex with its own unique label
    labels = collect(1:n)
    
    # Track if any labels changed in this iteration
    changed = true
    iteration = 0
    
    while changed && iteration < max_iterations
        changed = false
        iteration += 1
        
        # Create a random order to visit vertices (important for convergence)
        visit_order = randperm(n)
        
        for v in visit_order
            # Get labels of all neighbors
            neighbor_labels = [labels[u] for u in neighbors(g, v)]
            
            # If vertex has no neighbors, keep its current label
            if isempty(neighbor_labels)
                continue
            end
            
            # Find the most frequent label among neighbors
            label_counts = Dict{Int, Int}()
            for label in neighbor_labels
                label_counts[label] = get(label_counts, label, 0) + 1
            end
            
            # Find label(s) with maximum frequency
            max_count = maximum(values(label_counts))
            most_frequent_labels = [label for (label, count) in label_counts if count == max_count]
            
            # If there's a tie, randomly pick one (or pick the smallest for determinism)
            new_label = minimum(most_frequent_labels)  # Use minimum for deterministic behavior
            
            # Update label if it changed
            if new_label != labels[v]
                labels[v] = new_label
                changed = true
            end
        end
    end
    
    # Relabel communities to be consecutive integers starting from 1
    unique_labels = sort(unique(labels))
    label_mapping = Dict(old_label => new_label for (new_label, old_label) in enumerate(unique_labels))
    final_communities = [label_mapping[label] for label in labels]
    
    return final_communities
end

"""
    detect_communities(g::SimpleGraph; max_iterations::Int = 100, seed::Int = 42) -> Vector{Int}

Detect communities in the graph using label propagation algorithm.
Returns a vector where communities[i] is the community ID for vertex i.
"""
function detect_communities(g::SimpleGraph; max_iterations::Int = 100, seed::Int = 42)
    return label_propagation_communities(g, max_iterations=max_iterations, seed=seed)
end
