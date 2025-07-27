#!/usr/bin/env julia

using SimpleWeightedGraphs, Graphs

# Test the add_edge! method signature to confirm it works
function test_add_edge_signature()
    println("Testing add_edge! method signature...")
    
    # Create a simple weighted graph
    g = SimpleWeightedGraph(5)
    
    # Test adding edges with weights (the exact signature from our code)
    println("Adding edge (1, 2) with weight 2.5...")
    result1 = add_edge!(g, 1, 2, 2.5)
    println("Result: $result1")
    
    println("Adding edge (2, 3) with weight 1.0...")
    result2 = add_edge!(g, 2, 3, 1.0)
    println("Result: $result2")
    
    println("Adding edge (3, 4) with weight 3.7...")
    result3 = add_edge!(g, 3, 4, 3.7)
    println("Result: $result3")
    
    # Check if edges were added correctly
    println("\nGraph info:")
    println("Number of edges: $(ne(g))")
    println("Number of vertices: $(nv(g))")
    
    # Check weights
    println("\nEdge weights:")
    for e in edges(g)
        println("Edge $(src(e)) -> $(dst(e)): weight = $(weight(e))")
    end
    
    return g
end

# Run the test
if abspath(PROGRAM_FILE) == @__FILE__
    test_add_edge_signature()
end
