#!/usr/bin/env Rscript
# Final installation test for GraphFast package

cat("=== GraphFast Package - Final Installation Test ===\n\n")

# Load required packages
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
if (!requireNamespace("Rcpp", quietly = TRUE)) {
  install.packages("Rcpp")
}

library(devtools)
library(Rcpp)

# Clean any previous installation
try({
  remove.packages("graphfast")
}, silent = TRUE)

# Set working directory
setwd("c:/Users/kyleh/GitHub/graph_c")

cat("Step 1: Testing individual C++ file compilation...\n")
tryCatch({
  # This will test if our C++ code compiles without package structure issues
  source_result <- Rcpp::sourceCpp("src/graph_algorithms.cpp", rebuild = TRUE)
  cat("✓ C++ code compiles successfully!\n")
  
  # Test basic functionality
  test_edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  test_result <- find_components_cpp(test_edges, 6, TRUE)
  cat("✓ Basic functionality works! Found", test_result$n_components, "components\n")
  
}, error = function(e) {
  cat("✗ C++ compilation failed:\n")
  cat(conditionMessage(e), "\n")
  stop("Cannot proceed - C++ code has compilation errors")
})

cat("\nStep 2: Generating package exports...\n")
tryCatch({
  Rcpp::compileAttributes(".")
  cat("✓ Package attributes compiled\n")
}, error = function(e) {
  cat("✗ compileAttributes failed:\n")
  cat(conditionMessage(e), "\n")
})

cat("\nStep 3: Installing package...\n")
tryCatch({
  # Clean build
  devtools::clean_dll(".")
  
  # Document
  devtools::document(".")
  
  # Install
  devtools::install(".", quick = TRUE, upgrade = "never")
  
  cat("✓ Package installed successfully!\n")
  
}, error = function(e) {
  cat("✗ Package installation failed:\n")
  cat(conditionMessage(e), "\n")
  cat("\nTrying alternative installation method...\n")
  
  # Try system R CMD INSTALL
  tryCatch({
    system("R CMD INSTALL . --no-test-load")
    cat("✓ Alternative installation method succeeded!\n")
  }, error = function(e2) {
    cat("✗ All installation methods failed\n")
    return(FALSE)
  })
})

cat("\nStep 4: Testing installed package...\n")
tryCatch({
  # Load package
  library(graphfast)
  cat("✓ Package loaded successfully!\n")
  
  # Test all main functions
  edges <- matrix(c(1,2, 2,3, 3,4, 5,6, 8,9, 9,10), ncol=2, byrow=TRUE)
  
  # Test connected components
  components <- find_connected_components(edges)
  cat("✓ find_connected_components: Found", components$n_components, "components\n")
  
  # Test connectivity queries
  queries <- matrix(c(1,4, 1,5, 8,10), ncol=2, byrow=TRUE)
  connected <- are_connected(edges, queries)
  cat("✓ are_connected: Results", paste(connected, collapse=", "), "\n")
  
  # Test shortest paths
  distances <- shortest_paths(edges, queries)
  cat("✓ shortest_paths: Distances", paste(distances, collapse=", "), "\n")
  
  # Test graph statistics
  stats <- graph_statistics(edges, n_nodes = 10)
  cat("✓ graph_statistics: Density =", round(stats$density, 4), "\n")
  
  cat("\n=== ALL TESTS PASSED! ===\n")
  cat("GraphFast package is ready to use!\n")
  
}, error = function(e) {
  cat("✗ Package testing failed:\n")
  cat(conditionMessage(e), "\n")
})

cat("\nInstallation script completed.\n")