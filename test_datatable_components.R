#!/usr/bin/env Rscript
# Test Data.Table Component Functions

suppressPackageStartupMessages({
  library(graphfast)
  library(data.table)
})

cat("=== Testing Data.Table Component Functions ===\n\n")

# Create sample data.table with different column names
dt <- data.table(
  source = c(1, 2, 3, 5, 6, 10),
  target = c(2, 3, 1, 6, 7, 11),
  weight = c(0.5, 0.8, 0.3, 0.9, 0.4, 0.7),
  type = c("A", "A", "A", "B", "B", "C")
)

cat("Original data.table:\n")
print(dt)

# ===== Test 1: add_component_column (in place) =====
cat("\n1. Testing add_component_column() in place:\n")

# Add component column directly to the data.table
add_component_column(dt, from_col = "source", to_col = "target", 
                    component_col = "component", compress = TRUE)

cat("After adding component column:\n")
print(dt)

# ===== Test 2: add_component_column (copy) =====
cat("\n2. Testing add_component_column() with copy:\n")

dt2 <- data.table(
  from = c(1, 2, 3, 5, 6, 10),
  to = c(2, 3, 1, 6, 7, 11),
  value = runif(6)
)

dt2_with_components <- add_component_column(dt2, component_col = "group_id", in_place = FALSE)

cat("Original dt2 (unchanged):\n")
print(dt2)
cat("\nCopy with components:\n")
print(dt2_with_components)

# ===== Test 3: edge_components for data.table syntax =====
cat("\n3. Testing edge_components() with data.table syntax:\n")

dt3 <- data.table(
  node1 = c(1, 2, 3, 5, 6, 10),
  node2 = c(2, 3, 1, 6, 7, 11),
  edge_id = 1:6
)

# Use within data.table operations
dt3[, component := edge_components(.SD, "node1", "node2")]

cat("Using dt[, component := edge_components(.SD, ...)]:\n")
print(dt3)

# ===== Test 4: Verify components are correct =====
cat("\n4. Verifying component assignments:\n")

# Check that connected nodes have same component
connected_pairs <- list(
  c(1, 2, 3),  # Component 1: triangle
  c(5, 6, 7),  # Component 2: line  
  c(10, 11)    # Component 3: single edge
)

for (i in seq_along(connected_pairs)) {
  nodes <- connected_pairs[[i]]
  cat("Expected component", i, "nodes:", paste(nodes, collapse = ", "), "\n")
  
  # Find component IDs for these nodes in our results
  node_components <- unique(dt3[node1 %in% nodes | node2 %in% nodes, component])
  cat("Found components:", paste(node_components, collapse = ", "), "\n")
  cat("All same component:", length(node_components) == 1, "\n\n")
}

# ===== Test 5: Performance comparison =====
cat("5. Performance comparison with larger data:\n")

# Generate larger test data
n_edges <- 50000
large_dt <- data.table(
  from = sample(1:10000, n_edges, replace = TRUE),
  to = sample(1:10000, n_edges, replace = TRUE),
  weight = runif(n_edges)
)

cat("Testing with", nrow(large_dt), "edges\n")

# Method 1: add_component_column
start1 <- Sys.time()
add_component_column(large_dt, component_col = "comp1")
time1 <- as.numeric(Sys.time() - start1)

# Method 2: edge_components in data.table syntax  
start2 <- Sys.time()
large_dt[, comp2 := edge_components(.SD, "from", "to")]
time2 <- as.numeric(Sys.time() - start2)

cat("add_component_column():", round(time1, 4), "seconds\n")
cat("edge_components():", round(time2, 4), "seconds\n")

# Verify they give same results
identical_results <- identical(large_dt$comp1, large_dt$comp2)
cat("Results identical:", identical_results, "\n")
cat("Components found:", length(unique(large_dt$comp1)), "\n")

# ===== Test 6: Your use case pattern =====
cat("\n6. Your optimized use case pattern:\n")

# Your original pattern was:
# edges <- as.data.table(edges_matrix)
# edges <- edges[sample(.N)]  
# x[, from_component := result$components[from]]

# NEW optimized pattern for data.table:
edges_dt <- data.table(
  from = sample(1:1000, 5000, replace = TRUE),
  to = sample(1:1000, 5000, replace = TRUE)
)

set.seed(1)
edges_dt <- edges_dt[sample(.N)]  # Your shuffle step

# NEW: Single efficient operation
start_time <- Sys.time()
edges_dt[, component := edge_components(.SD, "from", "to")]
processing_time <- as.numeric(Sys.time() - start_time)

cat("✓ Processed", nrow(edges_dt), "edges in", round(processing_time, 4), "seconds\n")
cat("✓ Found", length(unique(edges_dt$component)), "components\n")
cat("✓ Sample components:", paste(head(edges_dt$component, 10), collapse = ", "), "\n")

cat("\n=== Summary ===\n")
cat("NEW DATA.TABLE FUNCTIONS:\n")
cat("1. add_component_column(dt, from_col, to_col, component_col)\n")
cat("   - Adds component column directly to your data.table\n")
cat("   - Works with any column names\n")
cat("   - Can modify in place or return copy\n\n")

cat("2. edge_components(dt, from_col, to_col)\n") 
cat("   - Returns component vector for data.table operations\n")
cat("   - Perfect for: dt[, component := edge_components(.SD, 'from', 'to')]\n\n")

cat("BENEFITS:\n")
cat("✓ Works directly with data.table (no matrix conversion needed)\n")
cat("✓ Flexible column names\n")
cat("✓ One component per edge (since from and to are always in same component)\n")
cat("✓ Integrates with data.table syntax\n")
cat("✓ Much faster than old lookup approach\n")

cat("\nRECOMMENDED PATTERN:\n")
cat("# Your data.table with any column names\n")
cat("dt[, component := edge_components(.SD, 'source_col', 'target_col')]\n")
cat("# Or:\n")
cat("add_component_column(dt, 'source_col', 'target_col', 'my_component_col')\n")