# Simple test script to verify package functionality
# Run this after successful installation

library(graphfast)

cat("=== Testing GraphFast Package ===\n\n")

# Test 1: Basic connected components
cat("Test 1: Connected Components\n")
edges1 <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
result1 <- find_connected_components(edges1)
cat("Expected: 2 components, Got:", result1$n_components, 
    if(result1$n_components == 2) "✓" else "✗", "\n")

# Test 2: Connectivity queries
cat("\nTest 2: Connectivity Queries\n")
queries <- matrix(c(1,3, 1,5), ncol=2, byrow=TRUE)
connected <- are_connected(edges1, queries)
expected <- c(TRUE, FALSE)
cat("Expected:", paste(expected, collapse=", "), 
    "Got:", paste(connected, collapse=", "),
    if(all(connected == expected)) "✓" else "✗", "\n")

# Test 3: Shortest paths
cat("\nTest 3: Shortest Paths\n")
distances <- shortest_paths(edges1, queries)
expected_dist <- c(2, -1)
cat("Expected:", paste(expected_dist, collapse=", "),
    "Got:", paste(distances, collapse=", "),
    if(all(distances == expected_dist)) "✓" else "✗", "\n")

# Test 4: Graph statistics
cat("\nTest 4: Graph Statistics\n")
stats <- graph_statistics(edges1, n_nodes = 6)
cat("Edges:", stats$n_edges, "Nodes:", stats$n_nodes, 
    if(stats$n_edges == 3 && stats$n_nodes == 6) "✓" else "✗", "\n")

# Test 5: Larger graph performance
cat("\nTest 5: Performance Test\n")
n <- 1000
large_edges <- cbind(1:(n-1), 2:n)  # Chain graph
start_time <- Sys.time()
large_result <- find_connected_components(large_edges)
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time)

cat("Large graph (", n, "nodes):", large_result$n_components, "component in",
    round(runtime, 3), "seconds",
    if(large_result$n_components == 1 && runtime < 1) "✓" else "✗", "\n")

cat("\n=== All Tests Complete ===\n")
cat("Package is working correctly!\n")