# Quick test to see if the package is working
cat("Testing GraphFast package...\n")

# Try loading the package
tryCatch({
  library(graphfast)
  cat("✓ Package loaded successfully!\n")
  
  # Test the main function
  edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  result <- find_connected_components(edges)
  cat("✓ find_connected_components works! Found", result$n_components, "components\n")
  
  # Test connectivity
  queries <- matrix(c(1,3, 1,5), ncol=2, byrow=TRUE)
  connected <- are_connected(edges, queries)
  cat("✓ are_connected works! Results:", paste(connected, collapse=", "), "\n")
  
  cat("\n=== SUCCESS! Package is working! ===\n")
  cat("You can now use all GraphFast functions.\n")
  
}, error = function(e) {
  cat("✗ Error:", conditionMessage(e), "\n")
  
  # If loading failed, try reinstalling
  cat("Attempting to reinstall...\n")
  try({
    devtools::install(".", upgrade = "never")
    library(graphfast)
    cat("✓ Reinstall successful!\n")
  })
})