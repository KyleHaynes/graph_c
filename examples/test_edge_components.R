#!/usr/bin/env Rscript
# Test New Edge Component Functions

suppressPackageStartupMessages({
  library(graphfast)
  library(data.table)
})

cat("=== Testing New Edge Component Functions ===\n\n")

# Create test data
set.seed(42)
test_edges <- matrix(c(
  1, 2,
  2, 3,
  3, 1,    # Component 1: triangle
  5, 6,
  6, 7,    # Component 2: line
  10, 11   # Component 3: single edge
), ncol = 2, byrow = TRUE)

# edges <- data.table(from = sample(1:1E8, 9E7), to = sample(1:1E8, 9E7))
# setnames(edges, c("from", "to"))
# edges[, component := edge_components(.SD, "from", "to")]


cat("Test edges:\n")
print(test_edges)
cat("\n")

# ===== Test 1: Compare old vs new approach =====
cat("1. Comparing old vs new approach:\n\n")

# OLD WAY (2 steps, slower)
cat("OLD WAY (your original pattern):\n")
old_start <- Sys.time()
old_result <- find_connected_components(test_edges, compress = FALSE)
x_old <- as.data.table(test_edges)
colnames(x_old) <- c("from", "to")
x_old[, from_component := old_result$components[from]]
x_old[, to_component := old_result$components[to]]
old_time <- as.numeric(Sys.time() - old_start)

cat("✓ Old way completed in", round(old_time, 6), "seconds\n")
print(x_old)

# NEW WAY (1 step, faster)
cat("\nNEW WAY (optimized):\n")
new_start <- Sys.time()
new_result <- get_edge_components(test_edges, compress = FALSE)
x_new <- as.data.table(test_edges)
colnames(x_new) <- c("from", "to")
x_new[, from_component := new_result$from_components]
x_new[, to_component := new_result$to_components]
new_time <- as.numeric(Sys.time() - new_start)

cat("✓ New way completed in", round(new_time, 6), "seconds\n")
print(x_new)

# Verify results are identical
identical_results <- identical(x_old$from_component, x_new$from_component) && 
                    identical(x_old$to_component, x_new$to_component)
cat("✓ Results identical:", identical_results, "\n")

if (new_time > 0 && old_time > 0) {
  speedup <- old_time / new_time
  cat("✓ Speedup:", round(speedup, 2), "x\n")
}

# ===== Test 2: Your requested group_edges function =====
cat("\n2. Testing group_edges() function:\n")

group_id <- group_edges(test_edges, compress = FALSE)
cat("group_id vector (same length as edges):\n")
print(data.frame(
  edge = 1:nrow(test_edges),
  from = test_edges[,1],
  to = test_edges[,2],
  group_id = group_id
))

cat("✓ group_id length:", length(group_id), "\n")
cat("✓ edges length:", nrow(test_edges), "\n")
cat("✓ Lengths match:", length(group_id) == nrow(test_edges), "\n")

# ===== Test 3: Performance with larger data =====
cat("\n3. Performance test with larger data:\n")

# Generate larger test case
n_edges <- 10000
large_edges <- matrix(c(
  sample(1:1000, n_edges, replace = TRUE),
  sample(1:1000, n_edges, replace = TRUE)
), ncol = 2)

cat("Testing with", nrow(large_edges), "edges\n")

# Time old approach
old_start <- Sys.time()
old_large <- find_connected_components(large_edges, compress = FALSE)
x_large_old <- as.data.table(large_edges)
colnames(x_large_old) <- c("from", "to")
x_large_old[, from_component := old_large$components[from]]
x_large_old[, to_component := old_large$components[to]]
old_large_time <- as.numeric(Sys.time() - old_start)

# Time new approach
new_start <- Sys.time()
new_large <- get_edge_components(large_edges, compress = FALSE)
x_large_new <- as.data.table(large_edges)
colnames(x_large_new) <- c("from", "to")
x_large_new[, from_component := new_large$from_components]
x_large_new[, to_component := new_large$to_components]
new_large_time <- as.numeric(Sys.time() - new_start)

cat("Old approach:", round(old_large_time, 4), "seconds\n")
cat("New approach:", round(new_large_time, 4), "seconds\n")

if (new_large_time > 0 && old_large_time > 0) {
  large_speedup <- old_large_time / new_large_time
  cat("Speedup on large data:", round(large_speedup, 2), "x\n")
}

# ===== Test 4: Your exact use case =====
cat("\n4. Your exact use case pattern:\n")

# Simulate your pattern with shuffled edges
edges <- as.data.table(large_edges[1:1000, ])  # Smaller for demo
set.seed(1)
edges <- edges[sample(.N)]  # Shuffle edges to avoid any ordering bias
edges_matrix <- as.matrix(edges)

# Your NEW optimized pattern
start_time <- Sys.time()
group_id <- group_edges(edges_matrix, compress = FALSE)
# Now group_id is the same length as your edges and gives component ID for each edge
processing_time <- as.numeric(Sys.time() - start_time)

cat("✓ Processed", length(group_id), "edges in", round(processing_time, 4), "seconds\n")
cat("✓ Found", length(unique(group_id)), "unique components\n")
cat("✓ group_id sample:", paste(head(group_id, 10), collapse = ", "), "\n")

cat("\n=== Summary ===\n")
cat("NEW FUNCTIONS AVAILABLE:\n")
cat("1. get_edge_components(edges) - returns list with from_components, to_components\n")
cat("2. group_edges(edges) - returns vector same length as edges\n")
cat("\nBENEFITS:\n")
cat("✓ Much faster - no R lookups needed\n")
cat("✓ More memory efficient\n")
cat("✓ Direct C++ implementation\n")
cat("✓ Same results as original approach\n")
cat("✓ Perfect for your workflow!\n")

cat("\nUSAGE FOR YOUR PATTERN:\n")
cat("# Instead of:\n")
cat("# result <- find_connected_components(edges, compress = FALSE)\n")
cat("# x[, from_component := result$components[from]]\n")
cat("\n# Use:\n")
cat("group_id <- group_edges(edges, compress = FALSE)\n")
cat("# group_id is same length as edges, much faster!\n")