# Quick installation test script
cat("=== Installing GraphFast Package ===\n")

# Try to install
tryCatch({
  devtools::install()
  cat("✓ Package installed successfully!\n")
  
  # Test basic functionality
  library(graphfast)
  cat("✓ Package loaded successfully!\n")
  
  # Quick test
  edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  result <- find_connected_components(edges)
  cat("✓ Basic function test passed! Found", result$n_components, "components\n")
  
  cat("\n=== Installation Complete ===\n")
  cat("Package is ready to use!\n")
  
}, error = function(e) {
  cat("✗ Installation failed:\n")
  cat(as.character(e), "\n")
  cat("\nTrying troubleshooting steps...\n")
  
  # Clean and retry
  tryCatch({
    devtools::clean_dll()
    devtools::document()
    devtools::install()
    cat("✓ Installation succeeded after cleanup!\n")
  }, error = function(e2) {
    cat("✗ Installation still failing:\n")
    cat(as.character(e2), "\n")
  })
})