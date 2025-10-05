# Debugging the "could not find function" error
cat("=== Debugging GraphFast Function Issue ===\n")

# First, check what's currently loaded
cat("Currently loaded packages:\n")
print(search())

# Check if graphfast is installed
if ("graphfast" %in% installed.packages()[,"Package"]) {
  cat("✓ GraphFast package is installed\n")
} else {
  cat("✗ GraphFast package is NOT installed\n")
  cat("Installing now...\n")
  devtools::install(".", upgrade = "never")
}

# Try to load the package
cat("\nAttempting to load GraphFast...\n")
tryCatch({
  library(graphfast)
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("✗ Failed to load package:", conditionMessage(e), "\n")
  return()
})

# Check what functions are available
cat("\nAvailable GraphFast functions:\n")
graphfast_functions <- ls("package:graphfast")
print(graphfast_functions)

# Check specifically for our C++ functions
cpp_functions <- c("find_components_cpp", "are_connected_cpp", "shortest_paths_cpp", "graph_stats_cpp")
for (func in cpp_functions) {
  if (exists(func)) {
    cat("✓", func, "is available\n")
  } else {
    cat("✗", func, "is NOT available\n")
  }
}

# Check for the main R interface functions
r_functions <- c("find_connected_components", "are_connected", "shortest_paths", "graph_statistics")
for (func in r_functions) {
  if (exists(func)) {
    cat("✓", func, "is available\n")
  } else {
    cat("✗", func, "is NOT available\n")
  }
}

# Now try the exact code that failed
cat("\nTesting the exact code that failed...\n")
edges1 <- matrix(c(1,2, 2,3, 5,6, 8,9, 9,10), ncol=2, byrow=TRUE)

tryCatch({
  result1 <- find_connected_components(edges1)
  cat("✓ find_connected_components works! Found", result1$n_components, "components\n")
}, error = function(e) {
  cat("✗ find_connected_components failed:", conditionMessage(e), "\n")
  
  # Try calling the C++ function directly
  cat("Trying C++ function directly...\n")
  tryCatch({
    result_cpp <- find_components_cpp(edges1, max(edges1), TRUE)
    cat("✓ Direct C++ call works! Found", result_cpp$n_components, "components\n")
  }, error = function(e2) {
    cat("✗ Direct C++ call also failed:", conditionMessage(e2), "\n")
  })
})

cat("\nDebugging complete.\n")