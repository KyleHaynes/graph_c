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
n_edges <- 1000000  # 1 million edges
n_nodes <- 100000   # 100k nodes

cat("Generating test graph with", n_edges, "edges and", n_nodes, "possible nodes\n")

# Create simple random edges using sample
edges_dt <- data.table(
  from = sample(1:n_nodes, n_edges, replace = TRUE),
  to = sample(1:n_nodes, n_edges, replace = TRUE)
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
n_components_graphfast <- if (needs_safe_version) result$n_components else result$n_components
components_match <- n_components_graphfast == igraph_components$no
cat("Components count match:", components_match, 
    "(", n_components_graphfast, "vs", igraph_components$no, ")\n")

# Check if component assignments are consistent
# Note: Component IDs may differ, but the grouping should be the same
graphfast_groups <- x[, .(edges = .N), by = .(from_component, to_component)][order(from_component, to_component)]
igraph_groups <- x_igraph[, .(edges = .N), by = .(from_component, to_component)][order(from_component, to_component)]

# For validation, check if nodes that are in same component in GraphFast are also same in igraph
validation_sample <- sample(nrow(x), min(1000, nrow(x)))
same_component_graphfast <- x[validation_sample, from_component == to_component]
same_component_igraph <- x_igraph[validation_sample, from_component == to_component]
consistency_match <- all(same_component_graphfast == same_component_igraph, na.rm = TRUE)

cat("Edge component consistency:", consistency_match, "\n")

# Show sample results
cat("\n=== Sample Results (First 10 edges) ===\n")
cat("GraphFast results:\n")
print(head(x[, .(from, to, from_component, to_component)], 10))

cat("\nigraph results:\n")
print(head(x_igraph[, .(from, to, from_component, to_component)], 10))

# ===== MEMORY COMPARISON =====
cat("\n=== Memory Usage ===\n")
gc_info <- gc(verbose = FALSE)
cat("Current memory usage:", round(sum(gc_info[, "used"] * c(gc_info[1, "max"], 8)) / 1024^2, 1), "MB\n")

cat("\n=== Summary ===\n")
cat("✓ MASSIVE SCALE TEST: Analyzed", round(nrow(edges_matrix) / 1000000, 1), "MILLION edges\n")
cat("✓ Node ID range:", min(edges_matrix), "to", max(edges_matrix), "\n")
cat("✓ GraphFast:", round(graphfast_time, 2), "sec (", round(nrow(edges_matrix) / graphfast_time / 1000000, 1), "M edges/sec)\n")
cat("✓ igraph:   ", round(igraph_time, 2), "sec (", round(nrow(edges_matrix) / igraph_time / 1000000, 1), "M edges/sec)\n")
cat("✓ Speedup:", round(speedup, 2), "x\n")
cat("✓ Results consistent:", consistency_match, "\n")

if (speedup > 1.1) {
  cat("🚀 GraphFast shows significant performance advantage on massive datasets!\n")
  if (speedup > 10) {
    cat("⚡ EXTREME PERFORMANCE: GraphFast is over 10x faster!\n")
  }
} else if (speedup < 0.9) {
  cat("📊 igraph shows performance advantage\n")
} else {
  cat("⚖️  Performance is comparable between methods\n")
}

if (nrow(edges_matrix) >= 50000000) {
  cat("🎯 MASSIVE SCALE ACHIEVEMENT: Successfully processed 50+ million edges!\n")
}

cat("\nComparison completed successfully!\n")