#!/usr/bin/env Rscript
# Test large integer handling

# Demonstrate the integer overflow problem
large_val <- 22361810781
cat("Original value:", large_val, "\n")
cat("as.integer():", as.integer(large_val), "\n")
cat("is.na(as.integer()):", is.na(as.integer(large_val)), "\n")
cat("Max 32-bit int:", .Machine$integer.max, "\n")

# Show the problem with your test case
test_large <- c(22361810781, 1, 2, 3)
cat("\nTest values:", paste(test_large, collapse = ", "), "\n")
cat("After as.integer():", paste(as.integer(test_large), collapse = ", "), "\n")

# Potential solutions:
cat("\nSolution approaches:\n")
cat("1. Use as.numeric() instead of as.integer()\n")
cat("2. Map large IDs to consecutive small integers\n")
cat("3. Modify C++ to use long long or double\n")

# Test node ID mapping approach
cat("\n=== Node ID Mapping Approach ===\n")
original_ids <- c(22361810781, 22361810782, 1000000000, 22361810783, 1000000001)
cat("Original IDs:", paste(original_ids, collapse = ", "), "\n")

# Create mapping to consecutive integers
unique_ids <- sort(unique(original_ids))
id_mapping <- setNames(seq_along(unique_ids), unique_ids)
mapped_ids <- id_mapping[as.character(original_ids)]

cat("Mapped IDs:", paste(mapped_ids, collapse = ", "), "\n")
cat("Mapping table:\n")
print(data.frame(original = unique_ids, mapped = seq_along(unique_ids)))