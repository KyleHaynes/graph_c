# Load required libraries.
require(graphfast)
require(data.table)

# Create a large data.table with random edges.
edges_dt <- data.table(
  x = sample(1E11, 100E6),
  y = sample(1E11, 100E6)
)

# edges_dt <- edges_dt[1:30E6]  # Use a subset for testing.

edges_dt[, x := as.numeric(as.factor(x))]
edges_dt[, y := as.numeric(as.factor(y))]


# Measure performance of edge_components on large data.table.
system.time({
     add_component_column(edges_dt, from_col = "x", to_col = "y", component_col = "group_id")
}, gcFirst = FALSE)



# Load required libraries.
require(graphfast)
require(data.table)

edges_dt <- data.table(
  x = sample(1:1E9, 10E6),
  y = sample(1:1E9, 10E6)
)

# edges_dt <- edges_dt[1:30E6]  # Use a subset for testing.
# # Fast method using data.table::frank() - much faster than factor conversion
# edges_dt[, x := frank(x, ties.method = "dense")]
# edges_dt[, y := frank(y, ties.method = "dense")]

# Measure performance of edge_components on large data.table.
system.time({
     add_component_column(edges_dt, from_col = "x", to_col = "y", component_col = "group_id")
}, gcFirst = FALSE)
