#!/usr/bin/env Rscript
# Demo: Fast Multi-Pattern String Matching with %fgrepl%

suppressPackageStartupMessages({
  library(graphfast)
})

cat("=== %fgrepl% Infix Operator Demo ===\n\n")

# Sample data
strings <- c(
  "error.log",
  "data.csv", 
  "temp.txt",
  "config.json",
  "test_results.log",
  "backup.tmp",
  "user_data.xml"
)

patterns <- c("log", "tmp", "test")

cat("Strings:\n")
for (i in seq_along(strings)) {
  cat(paste0("  ", i, ". ", strings[i], "\n"))
}

cat("\nPatterns:", paste(patterns, collapse = ", "), "\n\n")

# Using the infix operator
cat("Using %fgrepl% operator:\n")
result <- strings %fgrepl% patterns

cat("Results:\n")
for (i in seq_along(strings)) {
  status <- if(result[i]) "✓ MATCH" else "✗ no match"
  cat(paste0("  ", strings[i], " → ", status, "\n"))
}

cat("\nMatching strings:\n")
matching_strings <- strings[result]
for (s in matching_strings) {
  cat(paste0("  ✓ ", s, "\n"))
}

# Case-insensitive example
cat("\n=== Case-Insensitive Example ===\n")
mixed_case_strings <- c("ERROR.LOG", "Data.CSV", "TEMP.txt", "Test_File.doc")
lower_patterns <- c("error", "temp", "test")

cat("Strings:", paste(mixed_case_strings, collapse = ", "), "\n")
cat("Patterns:", paste(lower_patterns, collapse = ", "), "\n")

# Case-sensitive (no matches)
case_sensitive <- mixed_case_strings %fgrepl% lower_patterns
cat("Case-sensitive matches:", sum(case_sensitive), "\n")

# Case-insensitive (should match)
case_insensitive <- mixed_case_strings %fgrepli% lower_patterns
cat("Case-insensitive matches:", sum(case_insensitive), "\n")

# Performance comparison
cat("\n=== Quick Performance Check ===\n")
large_strings <- rep(strings, 1000)  # 7000 strings
large_patterns <- patterns

# Method 1: Base R
base_start <- Sys.time()
base_result <- sapply(large_strings, function(s) any(sapply(large_patterns, function(p) grepl(p, s, fixed = TRUE))))
base_time <- as.numeric(Sys.time() - base_start)

# Method 2: Our infix operator
fast_start <- Sys.time()
fast_result <- large_strings %fgrepl% large_patterns
fast_time <- as.numeric(Sys.time() - fast_start)

cat("Base R approach:", round(base_time, 4), "seconds\n")
cat("Fast %fgrepl%:  ", round(fast_time, 4), "seconds\n")

if (fast_time > 0 && base_time > 0) {
  speedup <- base_time / fast_time
  cat("Speedup:", round(speedup, 1), "x faster\n")
}

results_match <- identical(as.logical(base_result), fast_result)
cat("Results identical:", results_match, "\n")

cat("\n=== Usage Summary ===\n")
cat("✓ strings %fgrepl% patterns    # Fast case-sensitive matching\n")
cat("✓ strings %fgrepli% patterns   # Fast case-insensitive matching\n")
cat("✓ Much faster than multiple grepl() calls\n")
cat("✓ Convenient infix syntax\n")
cat("✓ Perfect for filtering and data analysis\n")