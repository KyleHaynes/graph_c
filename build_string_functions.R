#!/usr/bin/env Rscript
# Quick build script to compile new C++ functions

cat("Building GraphFast package with new string functions...\n")

# Remove old package if installed
try(remove.packages("graphfast"), silent = TRUE)

# Clean and build
if (file.exists("src/graphfast.dll")) {
  file.remove("src/graphfast.dll")
}

# Build and install
devtools::document()
devtools::install(upgrade = "never")

cat("Package rebuilt. Testing string functions...\n")

# Quick test
library(graphfast)
test_result <- multi_grepl(c("hello", "world"), c("hello"))
cat("Test successful:", test_result, "\n")
cat("Ready to run string_benchmark.R\n")