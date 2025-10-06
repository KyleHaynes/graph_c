# Test compilation of simplified function
cat("Testing simplified C++ compilation...\n")

library(Rcpp)
setwd("c:/Users/kyleh/GitHub/graph_c")

tryCatch({
  # Test the simplified version first
  sourceCpp("test_compile.cpp")
  
  # Test with simple data
  test_data <- list(c("a", "b", "c"))
  result <- test_multi_column_group_cpp(test_data)
  
  cat("✓ Simplified version compiles!\n")
  print(result)
  
}, error = function(e) {
  cat("✗ Simplified compilation failed:\n")
  cat(as.character(e), "\n")
})