#!/usr/bin/env Rscript
# GraphFast vs igraph Performance Comparison
# Simple test script comparing connected components analysis

# Load required libraries
suppressPackageStartupMessages({
  library(graphfast)
  library(igraph)
  library(data.table)
})

cat("=== GraphFast vs igraph Comparison ===\n\n")

# Generate test data - simple graph for comparison
set.seed(42)

cat("Generating test graph\n")

# Create simple random edges using sample
edges_dt <- data.table(
  from = sample(5E8, 5E5),
  to = sample(5E8, 5E5)
)

# Remove self-loops
edges_dt <- edges_dt[from != to]
edges_matrix <- as.matrix(edges_dt)

cat("Generated", nrow(edges_matrix), "edges (after removing self-loops)\n")
cat("Node ID range:", min(edges_matrix), "to", max(edges_matrix), "\n")
cat("Unique nodes:", length(unique(c(edges_matrix[,1], edges_matrix[,2]))), "\n\n")

# ===== GRAPHFAST TEST =====
cat("=== GraphFast Analysis ===\n")

graphfast_start <- Sys.time()

# Use find_connected_components for the analysis
result <- find_connected_components(edges_matrix)

graphfast_end <- Sys.time()
graphfast_time <- as.numeric(graphfast_end - graphfast_start)

cat("✓ GraphFast completed in", round(graphfast_time, 4), "seconds\n")
cat("✓ Found", result$n_components, "components\n")
cat("✓ Edges processed:", nrow(edges_matrix), "\n")
cat("✓ Throughput:", round(nrow(edges_matrix) / graphfast_time / 1000000, 2), "million edges/second\n")

# ===== IGRAPH TEST =====
cat("\n=== igraph Analysis ===\n")
cat("Converting", nrow(edges_matrix), "edges to igraph format...\n")

igraph_start <- Sys.time()

# Convert to igraph format
g <- graph_from_data_frame(edges_dt, directed = FALSE)

# Find connected components
igraph_components <- components(g)

igraph_end <- Sys.time()
igraph_time <- as.numeric(igraph_end - igraph_start)

cat("✓ igraph completed in", round(igraph_time, 4), "seconds\n")
cat("✓ Found", igraph_components$no, "components\n")
cat("✓ Largest component:", max(igraph_components$csize), "nodes\n")
cat("✓ Throughput:", round(nrow(edges_matrix) / igraph_time / 1000000, 2), "million edges/second\n")

# ===== COMPARISON =====
cat("\n=== Performance Comparison ===\n")
speedup <- igraph_time / graphfast_time
cat("GraphFast time:", round(graphfast_time, 4), "seconds\n")
cat("igraph time:   ", round(igraph_time, 4), "seconds\n")
cat("Speedup:       ", round(speedup, 2), "x", 
    if(speedup > 1) " (GraphFast is faster)" else " (igraph is faster)", "\n")

# ===== RESULTS VALIDATION =====
cat("\n=== Results Validation ===\n")

# Check if same number of components found
components_match <- result$n_components == igraph_components$no
cat("Components count match:", components_match, 
    "(", result$n_components, "vs", igraph_components$no, ")\n")

cat("\n=== Summary ===\n")
cat("✓ Analyzed", round(nrow(edges_matrix) / 1000000, 1), "million edges\n")
cat("✓ Node ID range:", min(edges_matrix), "to", max(edges_matrix), "\n")
cat("✓ GraphFast:", round(graphfast_time, 2), "sec (", round(nrow(edges_matrix) / graphfast_time / 1000000, 1), "M edges/sec)\n")
cat("✓ igraph:   ", round(igraph_time, 2), "sec (", round(nrow(edges_matrix) / igraph_time / 1000000, 1), "M edges/sec)\n")
cat("✓ Speedup:", round(speedup, 2), "x\n")
cat("✓ Components match:", components_match, "\n")

if (speedup > 1.1) {
  cat("🚀 GraphFast shows performance advantage!\n")
} else if (speedup < 0.9) {
  cat("📊 igraph shows performance advantage\n")
} else {
  cat("⚖️  Performance is comparable between methods\n")
}

d <- data.table(a = result$components, b = igraph_components$membership)

cat("\nComparison completed successfully!\n")