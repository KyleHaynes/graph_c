#!/usr/bin/env Rscript
# Quick fix for std::bad_alloc memory error

cat("=== Quick Fix for Memory Error ===\n\n")

cat("PROBLEM: std::bad_alloc when processing large node IDs\n")
cat("CAUSE: Code allocates arrays sized by max(node_ID), not unique node count\n\n")

cat("SOLUTION: Use automatic node ID remapping\n\n")

# Demonstrate the issue
large_id <- 22361810781
memory_gb <- large_id * 12 / 1024^3
cat("Example: Node ID", large_id, "requires ~", round(memory_gb, 1), "GB memory\n")
cat("This causes std::bad_alloc error\n\n")

cat("IMMEDIATE FIX:\n")
cat("1. Use find_connected_components_safe() instead of find_connected_components()\n")
cat("2. Or manually remap your node IDs to consecutive integers\n\n")

cat("EXAMPLE USAGE:\n")
cat("# Load the safe function\n")
cat("source('R/graph_functions_safe.R')\n\n")
cat("# Your original code that failed:\n")
cat("# result <- find_connected_components(edges, compress = FALSE)\n\n")
cat("# Replace with:\n")
cat("result <- find_connected_components_safe(edges, compress = FALSE)\n\n")
cat("# Rest of your code works the same:\n")
cat("x <- as.data.table(edges)\n")
cat("colnames(x) <- c('from', 'to')\n")
cat("x[, from_component := result$components[as.character(from)]]\n")
cat("x[, to_component := result$components[as.character(to)]]\n\n")

cat("The safe function automatically:\n")
cat("✓ Maps large node IDs to small consecutive integers\n")
cat("✓ Calls C++ with safe memory requirements\n") 
cat("✓ Maps results back to your original node IDs\n")
cat("✓ Provides memory usage statistics\n\n")

cat("PERFORMANCE: Safe function is actually FASTER for sparse large IDs\n")
cat("because it processes fewer nodes!\n\n")

cat("To load the fix: source('R/graph_functions_safe.R')\n")