#!/usr/bin/env Rscript
# GraphFast vs igraph Performance Comparison
# Minimal test script comparing connected components analysis

# Load required libraries
suppressPackageStartupMessages({
  library(graphfast)
  library(igraph)
  library(data.table)
})

cat("=== GraphFast vs igraph Comparison ===\n\n")

# Generate test data - simple graph for comparison
set.seed(42)
n_edges <- 10000  # Start with manageable size
n_nodes <- 5000

cat("Generating test graph with", n_edges, "edges and ~", n_nodes, "nodes\n")

# Create test edges - mix of connected components
edges_list <- list()

# Component 1: Dense cluster (nodes 1-1000)
comp1_edges <- 2000
edges_list[[1]] <- data.table(
  from = sample(1:1000, comp1_edges, replace = TRUE),
  to = sample(1:1000, comp1_edges, replace = TRUE)
)

# Component 2: Sparse cluster (nodes 2001-3000) 
comp2_edges <- 1000
edges_list[[2]] <- data.table(
  from = sample(2001:3000, comp2_edges, replace = TRUE),
  to = sample(2001:3000, comp2_edges, replace = TRUE)
)

# Component 3: Small clusters (nodes 4001-5000)
comp3_edges <- 1000
edges_list[[3]] <- data.table(
  from = sample(4001:5000, comp3_edges, replace = TRUE),
  to = sample(4001:5000, comp3_edges, replace = TRUE)
)

# Random edges to connect some components
random_edges <- n_edges - sum(sapply(edges_list, nrow))
if (random_edges > 0) {
  edges_list[[4]] <- data.table(
    from = sample(1:n_nodes, random_edges, replace = TRUE),
    to = sample(1:n_nodes, random_edges, replace = TRUE)
  )
}

# Combine all edges
edges_dt <- rbindlist(edges_list)

# Remove self-loops
edges_dt <- edges_dt[from != to]

cat("Generated", nrow(edges_dt), "edges (after removing self-loops)\n\n")

# Test data preparation (your code)
cat("=== Data Preparation (Your Code) ===\n")

edges_dt <- data.table(x = sample(21474364, 1E6), 
                    y = sample(21478364, 1E6))

edges <- as.data.table(edges_dt)
# set.seed(1)
# edges <- edges[sample(.N)]  # Shuffle edges to avoid any ordering bias
edges_matrix <- as.matrix(edges)

cat("Data prepared:", nrow(edges_matrix), "edges shuffled\n\n")

# ===== GRAPHFAST TEST =====
cat("=== GraphFast Analysis ===\n")
graphfast_start <- Sys.time()

# Your exact code - but more efficient!
# Old way (2 steps):
# result <- find_connected_components(edges_matrix, compress = FALSE)
# x[, from_component := result$components[from]]

# New way (1 step, much faster):
result <- get_edge_components(edges_matrix, compress = FALSE)

# Component assignment (your code pattern - now much faster)
x <- as.data.table(edges_matrix)
colnames(x) <- c("from", "to")
x[, from_component := result$from_components]
x[, to_component := result$to_components]

graphfast_end <- Sys.time()
graphfast_time <- as.numeric(graphfast_end - graphfast_start)

cat("✓ GraphFast completed in", round(graphfast_time, 4), "seconds\n")
cat("✓ Found", result$n_components, "components\n")
cat("✓ Edges processed:", nrow(x), "\n")

# ===== IGRAPH TEST =====
cat("\n=== igraph Analysis ===\n")
igraph_start <- Sys.time()

# Convert to igraph format
g <- graph_from_data_frame(edges, directed = FALSE)

# Find connected components
igraph_components <- components(g)

# Create node-to-component mapping (equivalent to result$components)
igraph_node_components <- igraph_components$membership
names(igraph_node_components) <- V(g)$name

# Add component info to edges (equivalent to your code)
x_igraph <- as.data.table(edges_matrix)
colnames(x_igraph) <- c("from", "to")
x_igraph[, from_component := igraph_node_components[as.character(from)]]
# x_igraph[, to_component := igraph_node_components[as.character(to)]]

igraph_end <- Sys.time()
igraph_time <- as.numeric(igraph_end - igraph_start)

cat("✓ igraph completed in", round(igraph_time, 4), "seconds\n")
cat("✓ Found", igraph_components$no, "components\n")
cat("✓ Largest component:", max(igraph_components$csize), "nodes\n")

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
cat("✓ Both methods successfully analyzed", nrow(edges_matrix), "edges\n")
cat("✓ GraphFast:", round(graphfast_time, 4), "sec |", 
    "igraph:", round(igraph_time, 4), "sec\n")
cat("✓ Speedup:", round(speedup, 2), "x\n")
cat("✓ Results consistent:", consistency_match, "\n")

if (speedup > 1.1) {
  cat("🚀 GraphFast shows significant performance advantage!\n")
} else if (speedup < 0.9) {
  cat("📊 igraph shows performance advantage\n")
} else {
  cat("⚖️  Performance is comparable between methods\n")
}

cat("\nComparison completed successfully!\n")