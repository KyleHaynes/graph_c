# Comprehensive test of group_id function after successful compilation
cat("=== Comprehensive group_id Test ===\n")

# After successful package compilation, run this test

# Test 1: Basic functionality
cat("\n--- Test 1: Basic functionality ---\n")
test_data <- data.frame(
  id = 1:5,
  col1 = c("a", "b", "a", "", "c"),
  col2 = c("", "b", "x", "a", ""),
  col3 = c("y", "", "", "", "c"),
  stringsAsFactors = FALSE
)

print("Test data:")
print(test_data)

# Test the C++ function directly (after package compilation)
tryCatch({
  result <- multi_column_group_cpp(
    data = list(test_data$col1, test_data$col2, test_data$col3),
    incomparables = c(""),
    case_sensitive = TRUE,
    min_group_size = 1
  )
  
  cat("✓ C++ function works!\n")
  cat("Group IDs:", result$group_ids, "\n")
  cat("Number of groups:", result$n_groups, "\n")
  cat("Group sizes:", result$group_sizes, "\n")
  
  # Test the R wrapper
  group_ids_r <- group_id(test_data, 
                          cols = c("col1", "col2", "col3"),
                          incomparables = c(""))
  
  cat("✓ R wrapper works!\n")
  cat("R wrapper result:", group_ids_r, "\n")
  
  # Test detailed results
  detailed <- group_id(test_data, 
                       cols = c("col1", "col2", "col3"),
                       incomparables = c(""),
                       return_details = TRUE)
  
  cat("✓ Detailed results work!\n")
  print(detailed)
  
}, error = function(e) {
  cat("✗ Test failed:\n")
  cat(as.character(e), "\n")
})

# Test 2: Case sensitivity
cat("\n--- Test 2: Case sensitivity ---\n")
case_data <- data.frame(
  col1 = c("Apple", "APPLE", "apple", "Banana"),
  col2 = c("", "orange", "ORANGE", ""),
  stringsAsFactors = FALSE
)

tryCatch({
  # Case sensitive
  result_sensitive <- group_id(case_data, 
                              cols = c("col1", "col2"),
                              case_sensitive = TRUE,
                              incomparables = c(""))
  
  # Case insensitive  
  result_insensitive <- group_id(case_data,
                                cols = c("col1", "col2"), 
                                case_sensitive = FALSE,
                                incomparables = c(""))
  
  cat("Case sensitive groups:", result_sensitive, "\n")
  cat("Case insensitive groups:", result_insensitive, "\n")
  cat("✓ Case sensitivity works!\n")
  
}, error = function(e) {
  cat("✗ Case sensitivity test failed:\n")
  cat(as.character(e), "\n")
})

# Test 3: Performance test
cat("\n--- Test 3: Performance test ---\n")
n_test <- 1000
set.seed(42)

large_data <- data.frame(
  col1 = sample(c("a", "b", "c", "d", "", ""), n_test, replace = TRUE),
  col2 = sample(c("x", "y", "z", "", "", ""), n_test, replace = TRUE),
  col3 = sample(c("1", "2", "3", "", "", ""), n_test, replace = TRUE),
  stringsAsFactors = FALSE
)

tryCatch({
  start_time <- Sys.time()
  
  perf_result <- group_id(large_data,
                         cols = c("col1", "col2", "col3"),
                         incomparables = c(""),
                         min_group_size = 2)
  
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time, units = "secs")
  
  cat(sprintf("✓ Processed %d rows in %.3f seconds\n", n_test, elapsed))
  cat(sprintf("Rate: %.0f rows/second\n", n_test / elapsed))
  cat(sprintf("Found %d groups\n", length(unique(perf_result[perf_result > 0]))))
  
}, error = function(e) {
  cat("✗ Performance test failed:\n")
  cat(as.character(e), "\n")
})

# Test 4: data.table integration (if available)
if (requireNamespace("data.table", quietly = TRUE)) {
  cat("\n--- Test 4: data.table integration ---\n")
  
  library(data.table)
  
  tryCatch({
    dt <- as.data.table(test_data)
    
    add_group_ids(dt, 
                  cols = c("col1", "col2", "col3"),
                  group_col = "entity_id",
                  incomparables = c(""))
    
    cat("✓ data.table integration works!\n")
    print(dt)
    
  }, error = function(e) {
    cat("✗ data.table test failed:\n")
    cat(as.character(e), "\n")
  })
}

cat("\n=== Test Suite Complete ===\n")
cat("Run this after successful package compilation:\n")
cat("1. devtools::document()\n")
cat("2. devtools::install()\n")
cat("3. library(graphfast)\n")
cat("4. source('comprehensive_test.R')\n")