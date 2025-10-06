#!/usr/bin/env Rscript
# Minimal GraphFast vs igraph Comparison
# Testing the exact code pattern you specified

suppressPackageStartupMessages({
  library(graphfast)
  library(igraph)
  library(data.table)
})

cat("=== Minimal GraphFast vs igraph Test ===\n")

# Simple test graph
test_edges <- data.table(
  from = c(sample(21474847, 1E6)),
  to   = c(sample(21474847, 1E6))
)

cat("Test graph:", nrow(test_edges), "edges\n")
print(test_edges)

cat("\n===============================\n")

# ===== YOUR GRAPHFAST CODE =====
cat("=== GraphFast (Your Code) ===\n")

# Exact code you specified
edges <- as.data.table(test_edges)
# set.seed(1)
# edges <- edges[sample(.N)]  # Shuffle edges to avoid any ordering bias
edges <- as.matrix(edges)

analysis_start <- Sys.time()
result <- find_connected_components(edges, compress = FALSE)

### And here (your second code block)
x <- as.data.table(edges)
colnames(x) <- c("from", "to")
x[, from_component := result$components[from]]
x[, to_component := result$components[to]]

graphfast_time <- as.numeric(Sys.time() - analysis_start)

cat("✓ Time:", round(graphfast_time, 6), "seconds\n")
cat("✓ Components found:", result$n_components, "\n")
cat("✓ Component sizes:", paste(result$component_sizes, collapse = ", "), "\n")

cat("\nEdges with component assignments:\n")
print(x[order(from, to)])

# ===== IGRAPH EQUIVALENT =====
cat("\n=== igraph Equivalent ===\n")

igraph_start <- Sys.time()

# Convert to igraph
g <- graph_from_data_frame(test_edges, directed = FALSE)
igraph_comp <- components(g)

# Create equivalent node-to-component mapping
igraph_components <- igraph_comp$membership
names(igraph_components) <- V(g)$name

# Apply to edges (equivalent to your code)
x_igraph <- as.data.table(edges)  # Use same shuffled edges
colnames(x_igraph) <- c("from", "to")
x_igraph[, from_component := igraph_components[as.character(from)]]
x_igraph[, to_component := igraph_components[as.character(to)]]

igraph_time <- as.numeric(Sys.time() - igraph_start)

cat("✓ Time:", round(igraph_time, 6), "seconds\n")
cat("✓ Components found:", igraph_comp$no, "\n")
cat("✓ Component sizes:", paste(igraph_comp$csize, collapse = ", "), "\n")

cat("\nEdges with component assignments:\n")
print(x_igraph[order(from, to)])

# ===== COMPARISON =====
cat("\n=== Comparison ===\n")
cat("GraphFast time:", round(graphfast_time, 6), "seconds\n")
cat("igraph time:   ", round(igraph_time, 6), "seconds\n")

if (graphfast_time > 0 && igraph_time > 0) {
  speedup <- igraph_time / graphfast_time
  cat("Speedup:       ", round(speedup, 2), "x\n")
} else {
  cat("Times too small to compare reliably\n")
}

# Validate results match
components_match <- result$n_components == igraph_comp$no
cat("Same # components:", components_match, "\n")

# Check if same edges are intra-component
graphfast_intra <- x[, from_component == to_component]
igraph_intra <- x_igraph[, from_component == to_component]
intra_match <- all(graphfast_intra == igraph_intra, na.rm = TRUE)
cat("Same intra-component edges:", intra_match, "\n")

cat("\n✓ Minimal comparison completed!\n")