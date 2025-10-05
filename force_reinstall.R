# Force complete reinstall of GraphFast package
cat("=== Force Reinstalling GraphFast ===\n")

# Remove any existing installation
try({
  remove.packages("graphfast")
  cat("✓ Removed existing installation\n")
}, silent = TRUE)

# Clean everything
try({
  devtools::clean_dll(".")
  cat("✓ Cleaned DLL files\n")
}, silent = TRUE)

# Set working directory to package root
setwd("c:/Users/kyleh/GitHub/graph_c")

# Regenerate exports (this should create both RcppExports.R and RcppExports.cpp)
cat("Regenerating Rcpp exports...\n")
Rcpp::compileAttributes(".")

# Document the package
cat("Documenting package...\n")
devtools::document(".")

# Install fresh
cat("Installing package...\n")
devtools::install(".", upgrade = "never", quick = FALSE)

# Test
cat("Testing installation...\n")
library(graphfast)

# Simple test
edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
result <- find_connected_components(edges)
cat("SUCCESS! Found", result$n_components, "components\n")

cat("GraphFast is now ready to use!\n")