#!/usr/bin/env Rscript
# Test Multi-Pattern String Matching Functions

suppressPackageStartupMessages({
  library(graphfast)
  library(data.table)
})

cat("=== Testing Multi-Pattern String Matching ===\n\n")

# Create test data
test_strings <- c(
  "hello world", 
  "goodbye cruel world", 
  "hello there", 
  "world peace",
  "neither here nor there",
  "Hello World",  # Different case
  "HELLO WORLD"   # All caps
)

test_patterns <- c("hello", "world")

cat("Test strings:\n")
for (i in seq_along(test_strings)) {
  cat(paste0(i, ". \"", test_strings[i], "\"\n"))
}

cat("\nTest patterns:", paste(paste0("\"", test_patterns, "\""), collapse = ", "), "\n\n")

# ===== Test 1: Basic functionality =====
cat("1. Basic multi_grepl() functionality:\n")

# Check if any pattern matches
any_match <- multi_grepl(test_strings, test_patterns, match_any = TRUE)
cat("Any pattern matches:\n")
print(data.frame(
  string = test_strings,
  matches = any_match,
  stringsAsFactors = FALSE
))

# Detailed pattern matching
cat("\nDetailed pattern matching (match_any = FALSE):\n")
detailed_match <- multi_grepl(test_strings, test_patterns, match_any = FALSE)
print(detailed_match)

# ===== Test 2: Case sensitivity =====
cat("\n2. Case sensitivity testing:\n")

case_sensitive <- multi_grepl(test_strings, test_patterns, ignore_case = FALSE)
case_insensitive <- multi_grepl(test_strings, test_patterns, ignore_case = TRUE)

cat("Case sensitive matches:\n")
print(data.frame(
  string = test_strings,
  matches = case_sensitive
))

cat("\nCase insensitive matches:\n")
print(data.frame(
  string = test_strings,
  matches = case_insensitive
))

# ===== Test 3: filter_strings() function =====
cat("\n3. Testing filter_strings() function:\n")

matching_strings <- filter_strings(test_strings, test_patterns)
non_matching_strings <- filter_strings(test_strings, test_patterns, invert = TRUE)

cat("Strings containing any pattern:\n")
for (s in matching_strings) {
  cat(paste0("  \"", s, "\"\n"))
}

cat("\nStrings NOT containing any pattern:\n")
for (s in non_matching_strings) {
  cat(paste0("  \"", s, "\"\n"))
}

# ===== Test 4: Performance comparison =====
cat("\n4. Performance comparison with base R:\n")

# Generate larger test data
n_strings <- 10000
large_strings <- paste0("string_", sample(1:1000, n_strings, replace = TRUE), 
                       "_", sample(c("hello", "world", "test", "data", "other"), n_strings, replace = TRUE))
large_patterns <- c("hello", "world", "test")

cat("Testing with", length(large_strings), "strings and", length(large_patterns), "patterns\n")

# Method 1: Base R approach
base_r_start <- Sys.time()
base_r_result <- sapply(large_strings, function(s) {
  any(sapply(large_patterns, function(p) grepl(p, s, fixed = TRUE)))
})
base_r_time <- as.numeric(Sys.time() - base_r_start)

# Method 2: Our C++ approach
cpp_start <- Sys.time()
cpp_result <- multi_grepl(large_strings, large_patterns, match_any = TRUE)
cpp_time <- as.numeric(Sys.time() - cpp_start)

cat("Base R approach:", round(base_r_time, 4), "seconds\n")
cat("C++ approach:   ", round(cpp_time, 4), "seconds\n")

if (cpp_time > 0 && base_r_time > 0) {
  speedup <- base_r_time / cpp_time
  cat("Speedup:", round(speedup, 2), "x\n")
}

# Verify results are identical
results_match <- identical(as.logical(base_r_result), cpp_result)
cat("Results identical:", results_match, "\n")

if (!results_match) {
  cat("WARNING: Results differ! Checking first few...\n")
  comparison <- data.frame(
    base_r = head(as.logical(base_r_result), 10),
    cpp = head(cpp_result, 10)
  )
  print(comparison)
}

# ===== Test 5: Different pattern scenarios =====
cat("\n5. Testing different pattern scenarios:\n")

# Empty patterns
empty_result <- multi_grepl(test_strings, character(0))
cat("Empty patterns result:", paste(empty_result, collapse = ", "), "\n")

# Single pattern
single_result <- multi_grepl(test_strings, "hello")
cat("Single pattern 'hello':", paste(single_result, collapse = ", "), "\n")

# Many patterns
many_patterns <- c("hello", "world", "goodbye", "peace", "there")
many_result <- multi_grepl(test_strings, many_patterns)
cat("Many patterns result:", paste(many_result, collapse = ", "), "\n")

# Special characters
special_strings <- c("hello.world", "test@example.com", "path/to/file", "key=value")
special_patterns <- c(".", "@", "/")
special_result <- multi_grepl(special_strings, special_patterns)
cat("Special characters - any match:", paste(special_result, collapse = ", "), "\n")

# ===== Test 6: Matrix output =====
cat("\n6. Testing matrix output:\n")

matrix_result <- multi_grepl(test_strings[1:4], test_patterns, 
                           match_any = FALSE, return_matrix = TRUE)
cat("Matrix output with row/column names:\n")
print(matrix_result)

cat("\n=== Summary ===\n")
cat("NEW STRING MATCHING FUNCTIONS:\n")
cat("1. multi_grepl(strings, patterns, match_any = TRUE/FALSE)\n")
cat("   - Fast multi-pattern matching\n")
cat("   - Case sensitive/insensitive options\n")
cat("   - Returns logical vector or detailed matrix\n\n")

cat("2. filter_strings(strings, patterns, invert = FALSE)\n")
cat("   - Efficiently filter strings by multiple patterns\n")
cat("   - Option to invert selection\n\n")

cat("BENEFITS:\n")
cat("✓ Much faster than multiple grepl() calls\n")
cat("✓ Fixed string matching (no regex overhead)\n")
cat("✓ Case sensitive/insensitive options\n")
cat("✓ Flexible output formats\n")
cat("✓ Memory efficient C++ implementation\n")

if (exists("speedup") && speedup > 1) {
  cat("✓ Performance:", round(speedup, 1), "x faster than base R\n")
}

cat("\nUSE CASES:\n")
cat("- Log file filtering by multiple keywords\n")
cat("- Data cleaning with multiple unwanted patterns\n")
cat("- Feature detection in text data\n")
cat("- Fast string categorization\n")