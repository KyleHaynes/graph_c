# GraphFast Package - Compilation Troubleshooting Guide

## Common Compilation Issues and Solutions

### Issue 1: RcppArmadillo Header Conflict
**Error:** `"The file 'Rcpp.h' should not be included. Please correct to include only 'RcppArmadillo.h'."`

**Solution:** 
✅ **FIXED** - Updated `graph_algorithms.cpp` to only include `RcppArmadillo.h`, not both headers.

### Issue 2: Member Initialization Order Warning
**Error:** `warning: 'SparseGraph::n_nodes' will be initialized after 'SparseGraph::adj'`

**Solution:**
✅ **FIXED** - Reordered member variables and constructor initialization list.

### Issue 3: C++11 Fallback Warning
**Error:** `Using fallback compilation with Armadillo 14.6.3. Please consider defining -DARMA_USE_CURRENT and also removing C++11 compilation directive.`

**Solution:**
✅ **FIXED** - Updated Makevars to use C++14 and added `-DARMA_USE_CURRENT` flag.

### Issue 4: Missing Final Newline in DESCRIPTION
**Error:** `incomplete final line found on 'DESCRIPTION'`

**Solution:**
✅ **FIXED** - Added proper line ending to DESCRIPTION file.

## Alternative Installation Methods

### Method 1: Simple Rcpp Version (Recommended if RcppArmadillo fails)

```r
# Switch to simple version that only uses Rcpp
source("switch_version.R")
switch_to_simple()

# Then install
devtools::install()
```

### Method 2: Manual Installation Steps

```r
# Clean any previous installation attempts
remove.packages("graphfast", lib = .libPaths()[1])

# Update Rcpp if needed
install.packages("Rcpp")

# Generate fresh Rcpp exports
Rcpp::compileAttributes()

# Build and install
devtools::document()
devtools::install()
```

### Method 3: Force Clean Build

```r
# Complete clean build
devtools::clean_dll()
devtools::document()
devtools::check()
devtools::install()
```

## System Requirements Verification

### Check R and Rtools Installation
```r
# Check R version
R.version.string

# Check if compiler is available
pkgbuild::has_build_tools()

# Check Rtools (Windows)
pkgbuild::has_rtools()

# Check compiler details
pkgbuild::check_build_tools()
```

### Install Missing Dependencies
```r
# Install required packages
install.packages(c("Rcpp", "RcppArmadillo", "devtools", "pkgbuild"))

# For RcppArmadillo issues, try specific version
install.packages("RcppArmadillo", type = "source")
```

## Platform-Specific Solutions

### Windows
1. Install Rtools from: https://cran.r-project.org/bin/windows/Rtools/
2. Ensure Rtools is in PATH
3. Restart R session
4. Try simple version first: `switch_to_simple()`

### macOS
1. Install Xcode command line tools: `xcode-select --install`
2. Install gfortran if needed
3. Update R to latest version

### Linux
1. Install build essentials: `sudo apt-get install build-essential`
2. Install R development headers: `sudo apt-get install r-base-dev`
3. Install BLAS/LAPACK: `sudo apt-get install libblas-dev liblapack-dev`

## Debugging Compilation

### View Compilation Details
```r
# Install with verbose output
withr::with_envvar(
  c("PKG_BUILD_EXTRA_FLAGS" = "--verbose"),
  devtools::install()
)

# Or check manually
devtools::check()
```

### Test C++ Code Separately
```r
# Test individual functions
Rcpp::sourceCpp("src/graph_algorithms.cpp")

# Quick test
edges <- matrix(c(1,2, 2,3), ncol=2)
find_components_cpp(edges, 3, TRUE)
```

## Alternative Package Versions

### Version A: Full Featured (RcppArmadillo)
- Uses `graph_algorithms.cpp`
- Requires RcppArmadillo
- More advanced linear algebra support
- May have compatibility issues

### Version B: Simple (Rcpp Only)
- Uses `graph_algorithms_simple.cpp`  
- Only requires Rcpp
- More compatible across systems
- Slightly less optimized

### Switching Between Versions
```r
# Switch to simple version
source("switch_version.R")
switch_to_simple()
devtools::install()

# Switch back to full version
switch_to_armadillo()
devtools::install()
```

## Verification After Installation

### Basic Functionality Test
```r
library(graphfast)

# Quick test
edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
result <- find_connected_components(edges)
print(result$n_components)  # Should be 2

# Run full test suite
source("test_installation.R")
```

### Performance Benchmark
```r
# Test with larger graph
n <- 10000
edges <- cbind(1:(n-1), 2:n)
system.time(find_connected_components(edges))
# Should complete in < 1 second
```

## Getting Help

### If All Else Fails
1. **Use simple version**: Run `switch_to_simple()` and install
2. **Check system**: Verify R, Rtools, and compiler installation
3. **Update packages**: Update all dependencies to latest versions
4. **Report issue**: Include full error output and system details

### Minimal Working Example
If you need to report an issue, include:
```r
# System information
sessionInfo()
pkgbuild::check_build_tools()

# Exact error message
# Full compilation output
# Steps to reproduce
```

### Contact Information
- GitHub Issues: [repository_url]/issues
- Include: R version, OS, Rtools version, full error output

## Success Indicators

✅ **Package installed successfully**
✅ **`library(graphfast)` loads without errors**  
✅ **Basic functions work**: `find_connected_components()`, `are_connected()`
✅ **Test script runs**: `source("test_installation.R")` passes all tests
✅ **Performance acceptable**: Large graphs process in reasonable time

The package should now be ready for use with massive graph datasets!