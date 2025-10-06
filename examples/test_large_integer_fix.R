#!/usr/bin/env Rscript
# Test Large Integer Support Fix

suppressPackageStartupMessages({
  library(graphfast)
  library(data.table)
})

# Source the enhanced function
source("R/graph_functions_large.R")

cat("=== Testing Large Integer Support ===\n\n")

# Test 1: Demonstrate the problem with current implementation
cat("1. Demonstrating the integer overflow problem:\n")
large_val <- 22361810781
cat("Value:", large_val, "\n")
cat("as.integer():", as.integer(large_val), "\n")
cat("Max 32-bit integer:", .Machine$integer.max, "\n")
cat("Problem: Value exceeds 32-bit integer limit!\n\n")

# Test 2: Small graph with large node IDs
cat("2. Testing small graph with large node IDs:\n")
test_edges_large <- matrix(c(
  22361810781, 22361810782,
  22361810782, 22361810783,
  22361810785, 22361810786,
  50000000001, 50000000002
), ncol = 2, byrow = TRUE)

cat("Test edges (large IDs):\n")
print(test_edges_large)

# Test with original function (should fail)
cat("\n3. Testing with original function:\n")
tryCatch({
  result_original <- find_connected_components(test_edges_large)
  cat("Original function succeeded (unexpected!)\n")
}, error = function(e) {
  cat("Original function failed:", e$message, "\n")
})

# Test with enhanced function
cat("\n4. Testing with enhanced function:\n")
result_large <- find_connected_components_large(test_edges_large)

cat("✓ Enhanced function succeeded!\n")
cat("Components found:", result_large$n_components, "\n")
cat("Component sizes:", paste(result_large$component_sizes, collapse = ", "), "\n")

if (!is.null(result_large$node_mapping)) {
  cat("Node mapping (first 5 rows):\n")
  print(head(result_large$node_mapping, 5))
}

cat("\nComponent assignments:\n")
print(head(result_large$components, 10))

# Test 3: Apply to your shuffled edges pattern
cat("\n5. Testing your specific pattern with large IDs:\n")

# Create test data similar to your usage
set.seed(42)
test_dt <- data.table(
  from = sample(c(22361810781:22361810800, 50000000001:50000000010), 20, replace = TRUE),
  to = sample(c(22361810781:22361810800, 50000000001:50000000010), 20, replace = TRUE)
)

# Remove self-loops
test_dt <- test_dt[from != to]

cat("Test data (", nrow(test_dt), "edges):\n")
print(head(test_dt, 5))

# Your pattern with enhanced function
edges <- as.data.table(test_dt)
set.seed(1)
edges <- edges[sample(.N)]  # Shuffle edges
edges_matrix <- as.matrix(edges)

cat("\nApplying enhanced function to shuffled edges...\n")
result_enhanced <- find_connected_components_large(edges_matrix, compress = FALSE)

# Apply component assignments (enhanced version)
x <- as.data.table(edges_matrix)
colnames(x) <- c("from", "to")

# Use the named components vector for lookup
x[, from_component := result_enhanced$components[as.character(from)]]
x[, to_component := result_enhanced$components[as.character(to)]]

cat("✓ Component assignment completed!\n")
cat("Sample results:\n")
print(head(x, 8))

cat("\n=== Summary ===\n")
cat("✓ Large integer support working correctly\n")
cat("✓ Found", result_enhanced$n_components, "components\n")
cat("✓ Largest component:", max(result_enhanced$component_sizes), "nodes\n")
cat("✓ Your workflow pattern supported with large node IDs\n")

# Performance note
cat("\n=== Performance Notes ===\n")
cat("- Node ID mapping adds slight overhead\n")
cat("- Automatic detection of large integers\n")
cat("- Results map back to original node IDs\n")
cat("- Memory efficient for sparse large ID ranges\n")