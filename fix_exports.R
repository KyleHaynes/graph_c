# Fix the missing function issue
cat("Fixing GraphFast package exports and installation...\n")

# Set working directory
setwd("c:/Users/kyleh/GitHub/graph_c")

# Step 1: Generate RcppExports
cat("Step 1: Generating Rcpp exports...\n")
tryCatch({
  Rcpp::compileAttributes(".")
  cat("✓ Rcpp exports generated successfully\n")
}, error = function(e) {
  cat("✗ Failed to generate exports:", conditionMessage(e), "\n")
})

# Check if RcppExports files were created
if (file.exists("src/RcppExports.cpp")) {
  cat("✓ RcppExports.cpp created\n")
} else {
  cat("✗ RcppExports.cpp not found\n")
}

if (file.exists("R/RcppExports.R")) {
  cat("✓ RcppExports.R created\n")
} else {
  cat("✗ RcppExports.R not found\n")
}

# Step 2: Clean and reinstall
cat("\nStep 2: Cleaning and reinstalling package...\n")
tryCatch({
  # Remove any existing installation
  try(remove.packages("graphfast"), silent = TRUE)
  
  # Clean DLL
  devtools::clean_dll(".")
  
  # Document the package
  devtools::document(".")
  
  # Install
  devtools::install(".", quick = FALSE, upgrade = "never")
  
  cat("✓ Package installation completed\n")
  
}, error = function(e) {
  cat("✗ Installation failed:", conditionMessage(e), "\n")
})

# Step 3: Test the installation
cat("\nStep 3: Testing the installation...\n")
tryCatch({
  # Load the package
  library(graphfast)
  cat("✓ Package loaded successfully\n")
  
  # Test basic functionality
  edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  result <- find_connected_components(edges)
  cat("✓ find_connected_components works! Found", result$n_components, "components\n")
  
  cat("\n=== SUCCESS! Package is now working ===\n")
  
}, error = function(e) {
  cat("✗ Package test failed:", conditionMessage(e), "\n")
  cat("\nTrying direct C++ compilation test...\n")
  
  # Test direct C++ compilation
  tryCatch({
    Rcpp::sourceCpp("src/graph_algorithms.cpp")
    cat("✓ Direct C++ compilation works\n")
    
    # Test the function directly
    edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
    result <- find_components_cpp(edges, 6, TRUE)
    cat("✓ Direct function call works! Found", result$n_components, "components\n")
    
  }, error = function(e2) {
    cat("✗ Direct C++ compilation also failed:", conditionMessage(e2), "\n")
  })
})