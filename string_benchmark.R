#!/usr/bin/env Rscript
# Simple Multi-Pattern String Matching Benchmark

suppressPackageStartupMessages({
  library(graphfast)
  library(stringi)
})

# Generate test data
cat("Generating 5M random strings...\n")
set.seed(42)

n <- 5e6  # number of strings
min_len <- 1
max_len <- 30
set.seed(123)
lengths <- sample(min_len:max_len, n, replace = TRUE)
# Generate random strings efficiently
random_strings <- stri_rand_strings(n, lengths, pattern = "[A-Za-z0-9]")


patterns <- c("log", "tmp", "test", "ca", "da", "longer stringgggg", "far", "foo", "bar", "baz")
cat("Testing", length(random_strings), "strings with", length(patterns), "patterns\n\n")

# Benchmark 1: Multiple grepl calls
cat("1. Multiple grepl(fixed=TRUE) calls:\n")
start_time <- Sys.time()
result1 <- Reduce(`|`, lapply(patterns, function(p) grepl(p, random_strings, fixed = TRUE)))
time1 <- as.numeric(Sys.time() - start_time)
cat("   Time:", round(time1, 3), "seconds\n")
cat("   Matches:", sum(result1), "\n\n")

# Benchmark 2: Single regex with alternation
cat("2. Single grepl with regex alternation:\n")
regex_pattern <- paste(patterns, collapse = "|")
start_time <- Sys.time()
result2 <- grepl(regex_pattern, random_strings, perl = TRUE)
time2 <- as.numeric(Sys.time() - start_time)
cat("   Time:", round(time2, 3), "seconds\n")
cat("   Matches:", sum(result2), "\n\n")

# Benchmark 3: Our multi_grepl function
cat("3. multi_grepl() function:\n")
start_time <- Sys.time()
result3 <- multi_grepl(random_strings, patterns, match_any = TRUE)
time3 <- as.numeric(Sys.time() - start_time)
cat("   Time:", round(time3, 3), "seconds\n")
cat("   Matches:", sum(result3), "\n\n")

# Results comparison
cat("Results verification:\n")
cat("   Multiple grepl == regex:", identical(result1, result2), "\n")
cat("   Multiple grepl == multi_grepl:", identical(result1, result3), "\n")
cat("   Regex == multi_grepl:", identical(result2, result3), "\n\n")

# Performance summary
cat("Performance summary:\n")
fastest_time <- min(time1, time2, time3)
cat("   Multiple grepl speedup:", round(time1 / fastest_time, 2), "x\n")
cat("   Regex speedup:", round(time2 / fastest_time, 2), "x\n")
cat("   multi_grepl speedup:", round(time3 / fastest_time, 2), "x\n\n")

winner <- which.min(c(time1, time2, time3))
methods <- c("Multiple grepl", "Regex alternation", "multi_grepl")
cat("Winner:", methods[winner], "\n")