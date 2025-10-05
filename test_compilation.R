# Test compilation script
cat("=== Testing GraphFast Compilation ===\n")

# Clean any previous attempts
try(detach("package:graphfast", unload=TRUE), silent=TRUE)

# Test compiling individual C++ file first
cat("Testing individual C++ compilation...\n")
tryCatch({
  Rcpp::sourceCpp("src/graph_algorithms.cpp")
  cat("✓ C++ compilation successful!\n")
  
  # Test a simple function
  edges <- matrix(c(1,2, 2,3), ncol=2)
  result <- find_components_cpp(edges, 3, TRUE)
  cat("✓ Function test passed! Found", result$n_components, "components\n")
  
}, error = function(e) {
  cat("✗ C++ compilation failed:\n")
  print(e)
})

# Now try full package installation
cat("\nTesting full package installation...\n")
tryCatch({
  # Generate fresh exports
  Rcpp::compileAttributes()
  
  # Install package
  devtools::clean_dll()
  devtools::document()
  devtools::install()
  
  cat("✓ Package installation successful!\n")
  
  # Test package functions
  library(graphfast)
  edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  result <- find_connected_components(edges)
  cat("✓ Package test passed! Found", result$n_components, "components\n")
  
}, error = function(e) {
  cat("✗ Package installation failed:\n")
  print(e)
})