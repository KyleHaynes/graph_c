# Demonstration of edges vs components length mismatch and solution

library(graphfast)

cat("=== Understanding Edges vs Components Length Mismatch ===\n\n")

# Create a simple example
edges <- matrix(c(
  1, 2,  # Component 1
  2, 3,
  4, 5,  # Component 2
  6, 7,  # Component 3 
  7, 8,
  8, 6   # Forms a cycle in component 3
), ncol = 2, byrow = TRUE)

cat("Graph structure:\n")
cat("Edges matrix:", nrow(edges), "rows (each row = one edge)\n")
cat("Nodes in graph: 1, 2, 3, 4, 5, 6, 7, 8 (max node ID =", max(edges), ")\n\n")

# Analyze connected components
result <- find_connected_components(edges)

cat("Connected components analysis:\n")
cat("Number of components:", result$n_components, "\n")
cat("Component assignments length:", length(result$components), "\n")
cat("Component assignments: [", paste(result$components, collapse = ", "), "]\n")
cat("  (One value per NODE, indexed by node ID)\n\n")

# Demonstrate the length mismatch
cat("=== Length Mismatch Demonstration ===\n")
cat("edges has", nrow(edges), "rows (edges)\n")
cat("result$components has", length(result$components), "values (nodes)\n")
cat("Cannot directly assign because", nrow(edges), "≠", length(result$components), "\n\n")

# Show the CORRECT way to map components to edges
cat("=== CORRECT Solution: Map Components to Edges ===\n")

# Convert to data.table for easier manipulation
require(data.table)
dt <- as.data.table(edges)
colnames(dt) <- c("from", "to")

# Map component IDs to both source and target nodes
dt[, from_component := result$components[from]]
dt[, to_component := result$components[to]]

# Classify edges
dt[, edge_type := ifelse(from_component == to_component, "intra", "inter")]

cat("Edge-level analysis:\n")
print(dt)

cat("\nSummary:\n")
cat("- Intra-component edges (within same component):", sum(dt$edge_type == "intra"), "\n")
cat("- Inter-component edges (between components):", sum(dt$edge_type == "inter"), "\n")

# Explain what each means
cat("\n=== Explanation ===\n")
cat("• result$components[i] = component ID for node i\n")
cat("• For edge (from, to): \n")
cat("  - from_component = result$components[from]\n")
cat("  - to_component = result$components[to]\n")
cat("  - If from_component == to_component: edge is within same component\n")
cat("  - If from_component != to_component: edge bridges components\n")

cat("\n✓ Now the lengths match: edges data table has", nrow(dt), "rows with component info!\n")