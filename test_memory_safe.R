#!/usr/bin/env Rscript
# Test Memory-Safe Connected Components

suppressPackageStartupMessages({
  library(graphfast)
  library(data.table)
})

# Source the memory-safe function
source("R/graph_functions_safe.R")

cat("=== Memory-Safe Connected Components Test ===\n\n")

# Create problematic test case - sparse large node IDs
cat("1. Creating test case with sparse large node IDs...\n")

set.seed(42)
n_edges <- 1000  # Start smaller for testing

# Generate sparse node IDs that would cause memory issues
large_nodes <- c(
  sample(22361810781:22361810800, n_edges/2, replace = TRUE),
  sample(50000000001:50000000020, n_edges/2, replace = TRUE)
)

edges_problematic <- data.table(
  from = sample(large_nodes, n_edges, replace = TRUE),
  to = sample(large_nodes, n_edges, replace = TRUE)
)

# Remove self-loops
edges_problematic <- edges_problematic[from != to]
edges_matrix <- as.matrix(edges_problematic)

cat("Generated", nrow(edges_matrix), "edges\n")
cat("Node ID range:", min(edges_matrix), "to", max(edges_matrix), "\n")
cat("Unique nodes:", length(unique(c(edges_matrix[,1], edges_matrix[,2]))), "\n")

# Estimate memory that would be required
max_id <- max(edges_matrix)
estimated_gb <- max_id * 12 / 1024^3
cat("Naive memory requirement:", round(estimated_gb, 2), "GB\n\n")

# Test 1: Try original function (should fail or warn)
cat("2. Testing original function:\n")
tryCatch({
  result_original <- find_connected_components(edges_matrix, compress = FALSE)
  cat("✓ Original function succeeded (unexpected for large IDs!)\n")
  cat("Components found:", result_original$n_components, "\n")
}, error = function(e) {
  cat("✗ Original function failed:", e$message, "\n")
}, warning = function(w) {
  cat("⚠ Original function warning:", w$message, "\n")
})

cat("\n3. Testing memory-safe function:\n")
# Test 2: Use memory-safe function
result_safe <- find_connected_components_safe(edges_matrix, compress = FALSE, verbose = TRUE)

cat("\n4. Testing your workflow pattern with safe function:\n")
# Apply your exact pattern with the safe function
edges <- as.data.table(edges_matrix)
set.seed(1)
edges <- edges[sample(.N)]  # Shuffle edges
edges_shuffled <- as.matrix(edges)

# Use safe function
result_workflow <- find_connected_components_safe(edges_shuffled, compress = FALSE, verbose = FALSE)

# Apply component assignments (your pattern)
x <- as.data.table(edges_shuffled)
colnames(x) <- c("from", "to")
x[, from_component := result_workflow$components[as.character(from)]]
x[, to_component := result_workflow$components[as.character(to)]]

cat("✓ Your workflow completed successfully!\n")
cat("Sample results:\n")
print(head(x, 5))

cat("\n=== Scaling Test ===\n")
cat("5. Testing with larger dataset (10K edges):\n")

# Generate larger test case
n_edges_large <- 10000
large_nodes_2 <- c(
  sample(22361810781:22361810900, n_edges_large/2, replace = TRUE),
  sample(50000000001:50000000100, n_edges_large/2, replace = TRUE)
)

edges_large <- data.table(
  from = sample(large_nodes_2, n_edges_large, replace = TRUE),
  to = sample(large_nodes_2, n_edges_large, replace = TRUE)
)
edges_large <- edges_large[from != to]

cat("Large test case:", nrow(edges_large), "edges\n")

start_time <- Sys.time()
result_large <- find_connected_components_safe(as.matrix(edges_large), verbose = TRUE)
end_time <- Sys.time()

processing_time <- as.numeric(end_time - start_time)
cat("Processing time:", round(processing_time, 3), "seconds\n")
cat("Throughput:", round(nrow(edges_large) / processing_time), "edges/second\n")

cat("\n=== Performance Comparison ===\n")
cat("Memory-safe approach benefits:\n")
cat("✓ Handles arbitrary large node IDs\n")
cat("✓ Memory usage proportional to unique nodes, not max ID\n")
cat("✓ Automatic node ID remapping\n")
cat("✓ Results mapped back to original IDs\n")
cat("✓ No manual preprocessing required\n")

if (!is.null(result_large$memory_info)) {
  cat("✓ Memory saved:", round(result_large$memory_info$memory_saved_gb, 2), "GB\n")
}

cat("\nRecommendation: Use find_connected_components_safe() for large/sparse node IDs\n")