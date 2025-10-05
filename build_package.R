# GraphFast Package Installation and Build Script

# Check if required packages are installed
check_dependencies <- function() {
  required_packages <- c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown")
  missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
  
  if (length(missing_packages) > 0) {
    cat("Installing missing dependencies:", paste(missing_packages, collapse = ", "), "\n")
    install.packages(missing_packages)
  }
}

# Build and install the package
build_and_install <- function() {
  cat("Building and installing graphfast package...\n")
  
  # Generate documentation
  cat("Generating documentation...\n")
  devtools::document()
  
  # Run tests
  cat("Running tests...\n")
  devtools::test()
  
  # Check package
  cat("Checking package...\n")
  devtools::check()
  
  # Install package
  cat("Installing package...\n")
  devtools::install()
  
  cat("Installation complete!\n")
}

# Run the build process
main <- function() {
  cat("=== GraphFast Package Build Script ===\n\n")
  
  check_dependencies()
  build_and_install()
  
  cat("\n=== Testing Installation ===\n")
  
  # Test the installation
  library(graphfast)
  
  # Quick test
  test_edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  result <- find_connected_components(test_edges)
  
  cat("Test result - Components found:", result$n_components, "\n")
  cat("Package installation successful!\n")
}

# Run if script is executed directly
if (sys.nframe() == 0) {
  main()
}