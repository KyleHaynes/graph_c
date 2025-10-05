# Load required libraries.
require(graphfast)
require(data.table)

# Create a large data.table with random edges.
edges_dt <- data.table(
  x = sample(1E9, 180E6),
  y = sample(1E9, 180E6)
)

# Measure performance of edge_components on large data.table.
system.time({
    edges_dt[, component := edge_components(.SD, "x", "y")]
}, gcFirst = FALSE)
