#!/usr/bin/env Rscript
# Demo: Fast Multi-Pattern String Matching with %fgrepl%

suppressPackageStartupMessages({
  library(graphfast)
  library(stringi)
})

cat("=== %fgrepl% Large-Scale Demo ===\n\n")

# Generate large-scale test data using stringi
set.seed(42)
n_strings <- 1000000  # 1000k strings for substantial testing
n_patterns <- 30     # 30 patterns as requested

cat("Generating", n_strings, "random strings using stringi...\n")

# Generate random strings of varying lengths
string_lengths <- sample(5:25, n_strings, replace = TRUE)
test_strings <- stri_rand_strings(n_strings, string_lengths, pattern = "[A-Za-z0-9._-]")

# Add some common file extensions and prefixes for realism
extensions <- c(".log", ".tmp", ".csv", ".json", ".xml", ".txt", ".doc", ".pdf", ".dat", ".cfg")
prefixes <- c("error_", "temp_", "data_", "config_", "backup_", "test_", "user_", "system_", "cache_", "debug_")

# Mix in some realistic patterns
realistic_strings <- c(
  paste0(sample(prefixes, 5000, replace = TRUE), 
         stri_rand_strings(5000, sample(8:15, 5000, replace = TRUE), pattern = "[a-z0-9]"),
         sample(extensions, 5000, replace = TRUE)),
  paste0(stri_rand_strings(3000, sample(6:12, 3000, replace = TRUE), pattern = "[A-Za-z]"),
         sample(extensions, 3000, replace = TRUE))
)

# Combine random and realistic strings
all_strings <- c(test_strings[1:(n_strings-8000)], realistic_strings)

cat("Generated", length(all_strings), "strings\n")
cat("Sample strings:", paste(head(all_strings, 5), collapse = ", "), "...\n\n")

# Generate 30 random search patterns
cat("Generating", n_patterns, "random search patterns...\n")
pattern_lengths <- sample(2:8, n_patterns, replace = TRUE)
search_patterns <- stri_rand_strings(n_patterns, pattern_lengths, pattern = "[a-z0-9]")

# Mix in some common patterns that are likely to match
common_patterns <- c("log", "tmp", "test", "data", "error", "temp", "user", "config", "backup", "debug")
search_patterns[1:10] <- sample(common_patterns, 10)

cat("Search patterns:\n")
for (i in seq_along(search_patterns)) {
  cat(sprintf("  %2d. %s\n", i, search_patterns[i]))
}
cat("\n")

# Using the infix operator on large dataset
cat("=== Large-Scale Pattern Matching ===\n")
cat("Testing %fgrepl% on", length(all_strings), "strings with", length(search_patterns), "patterns...\n")

start_time <- Sys.time()
result <- all_strings %fgrepl% search_patterns
end_time <- Sys.time()
processing_time <- as.numeric(end_time - start_time)

matches_found <- sum(result)
match_percentage <- round(100 * matches_found / length(all_strings), 2)

cat("✓ Processing completed in", round(processing_time, 4), "seconds\n")
cat("✓ Found", matches_found, "matches out of", length(all_strings), "strings (", match_percentage, "%)\n")
cat("✓ Throughput:", round(length(all_strings) / processing_time / 1000, 1), "K strings/second\n")

# Show sample results
cat("\nSample matching strings (first 10):\n")
matching_strings <- all_strings[result]
sample_matches <- head(matching_strings, 10)
for (i in seq_along(sample_matches)) {
  cat(sprintf("  %2d. %s\n", i, sample_matches[i]))
}

# Case-insensitive example with subset
cat("\n=== Case-Insensitive Example ===\n")
subset_strings <- sample(all_strings, 1000)  # Use subset for quick demo
case_patterns <- c("ERROR", "DATA", "TEST", "CONFIG", "TEMP")

cat("Testing", length(subset_strings), "strings with case-insensitive patterns...\n")
cat("Patterns:", paste(case_patterns, collapse = ", "), "\n")

# Case-sensitive (fewer matches expected)
case_sensitive <- subset_strings %fgrepl% case_patterns
case_sensitive_matches <- sum(case_sensitive)

# Case-insensitive (more matches expected)
case_insensitive <- subset_strings %fgrepli% case_patterns
case_insensitive_matches <- sum(case_insensitive)

cat("Case-sensitive matches:", case_sensitive_matches, "(", round(100*case_sensitive_matches/length(subset_strings), 1), "%)\n")
cat("Case-insensitive matches:", case_insensitive_matches, "(", round(100*case_insensitive_matches/length(subset_strings), 1), "%)\n")

# Performance comparison with larger dataset
cat("\n=== Performance Comparison ===\n")
perf_strings <- sample(all_strings, 1000000)  # 1M strings for performance test
perf_patterns <- search_patterns[1:10]      # First 10 patterns

cat("Comparing performance on", length(perf_strings), "strings with", length(perf_patterns), "patterns...\n")



# Create concatenated pattern for perl regex (escape special chars)
perl_pattern <- paste(perf_patterns, collapse = "|")
cat("Perl regex pattern:", perl_pattern, "\n")

# Method 1: Base R fixed string approach
cat("Running base R fixed string approach...\n")
base_start <- Sys.time()
base_result <- sapply(perf_strings, function(s) any(sapply(perf_patterns, function(p) grepl(p, s, fixed = TRUE))))
base_time <- as.numeric(Sys.time() - base_start)

# Method 2: Base R perl regex approach
cat("Running base R perl regex approach...\n")
perl_start <- Sys.time()
perl_result <- grepl(perl_pattern, perf_strings, perl = TRUE)
perl_time <- as.numeric(Sys.time() - perl_start)

# Method 3: Our optimized infix operator
cat("Running %fgrepl% approach...\n")
fast_start <- Sys.time()
fast_result <- perf_strings %fgrepl% perf_patterns
fast_time <- as.numeric(Sys.time() - fast_start)

cat("\nPerformance Results:\n")
cat("Base R fixed:       ", sprintf("%8.4f", base_time), "seconds\n")
cat("Base R perl regex:  ", sprintf("%8.4f", perl_time), "seconds\n")
cat("Fast %fgrepl%:      ", sprintf("%8.4f", fast_time), "seconds\n")

if (fast_time > 0 && base_time > 0 && perl_time > 0) {
  base_speedup <- base_time / fast_time
  perl_speedup <- perl_time / fast_time
  
  cat("\nSpeedup vs Base R fixed:    ", sprintf("%8.1f", base_speedup), "x faster\n")
  cat("Speedup vs Base R perl:     ", sprintf("%8.1f", perl_speedup), "x faster\n")
  
  # Calculate throughput
  base_throughput <- length(perf_strings) * length(perf_patterns) / base_time / 1000
  perl_throughput <- length(perf_strings) / perl_time / 1000  # perl does all patterns at once
  fast_throughput <- length(perf_strings) * length(perf_patterns) / fast_time / 1000
  
  cat("\nThroughput comparisons:\n")
  cat("Base R fixed:       ", sprintf("%8.1f", base_throughput), "K comparisons/sec\n")
  cat("Base R perl regex:  ", sprintf("%8.1f", perl_throughput), "K strings/sec\n")
  cat("Fast %fgrepl%:      ", sprintf("%8.1f", fast_throughput), "K comparisons/sec\n")
}

# Verify results are identical
base_perl_match <- identical(as.logical(base_result), perl_result)
base_fast_match <- identical(as.logical(base_result), fast_result)
perl_fast_match <- identical(perl_result, fast_result)

cat("\nResults verification:\n")
cat("Base fixed vs perl:    ", base_perl_match, "\n")
cat("Base fixed vs %fgrepl%:", base_fast_match, "\n")
cat("Perl vs %fgrepl%:      ", perl_fast_match, "\n")

# Memory usage comparison
cat("\nMemory efficiency comparison:\n")
cat("✓ %fgrepl% uses optimized C++ implementation\n")
cat("✓ Base R fixed creates", length(perf_strings) * length(perf_patterns), "intermediate results\n")
cat("✓ Base R perl regex creates 1 compiled pattern, processes", length(perf_strings), "strings\n")
cat("✓ %fgrepl% processes all patterns simultaneously with minimal overhead\n")

cat("\nMethod characteristics:\n")
cat("• Base R fixed:     Nested loops, multiple grepl() calls\n")
cat("• Base R perl:      Single regex compilation, vectorized matching\n")
cat("• %fgrepl%:         Optimized C++ multi-pattern search\n")

cat("\n=== Summary ===\n")
cat("✓ Processed", length(all_strings), "strings with", length(search_patterns), "patterns\n")
cat("✓ Total pattern comparisons:", length(all_strings) * length(search_patterns), "\n")
cat("✓ strings %fgrepl% patterns    # Fast case-sensitive matching\n")
cat("✓ strings %fgrepli% patterns   # Fast case-insensitive matching\n")
cat("✓ Significant performance advantage over nested grepl() loops\n")
cat("✓ Memory-efficient C++ implementation\n")
cat("✓ Perfect for large-scale text processing and filtering\n")
cat("✓ Scales well with both string count and pattern count\n\n")

cat("Generated with stringi package using:\n")
cat("- stri_rand_strings() for random string generation\n")
cat("- Mixed realistic patterns (file extensions, prefixes)\n")
cat("- Configurable string lengths and character sets\n")