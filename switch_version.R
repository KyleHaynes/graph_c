# Script to switch between RcppArmadillo and simple Rcpp versions

switch_to_simple <- function() {
  cat("Switching to simple Rcpp version...\n")
  
  # Backup current files
  file.copy("DESCRIPTION", "DESCRIPTION_armadillo", overwrite = TRUE)
  file.copy("src/graph_algorithms.cpp", "src/graph_algorithms_armadillo.cpp", overwrite = TRUE)
  file.copy("src/Makevars", "src/Makevars_armadillo", overwrite = TRUE)
  file.copy("src/Makevars.win", "src/Makevars.win_armadillo", overwrite = TRUE)
  
  # Switch to simple versions
  file.copy("DESCRIPTION_simple", "DESCRIPTION", overwrite = TRUE)
  file.copy("src/graph_algorithms_simple.cpp", "src/graph_algorithms.cpp", overwrite = TRUE)
  file.copy("src/Makevars_simple", "src/Makevars", overwrite = TRUE)
  file.copy("src/Makevars_simple", "src/Makevars.win", overwrite = TRUE)
  
  cat("Switched to simple Rcpp version. Try installing now.\n")
}

switch_to_armadillo <- function() {
  cat("Switching to RcppArmadillo version...\n")
  
  # Switch back to RcppArmadillo versions
  if (file.exists("DESCRIPTION_armadillo")) {
    file.copy("DESCRIPTION_armadillo", "DESCRIPTION", overwrite = TRUE)
  }
  if (file.exists("src/graph_algorithms_armadillo.cpp")) {
    file.copy("src/graph_algorithms_armadillo.cpp", "src/graph_algorithms.cpp", overwrite = TRUE)
  }
  if (file.exists("src/Makevars_armadillo")) {
    file.copy("src/Makevars_armadillo", "src/Makevars", overwrite = TRUE)
  }
  if (file.exists("src/Makevars.win_armadillo")) {
    file.copy("src/Makevars.win_armadillo", "src/Makevars.win", overwrite = TRUE)
  }
  
  cat("Switched to RcppArmadillo version.\n")
}

# Main function
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) == 0) {
    cat("Usage: Rscript switch_version.R [simple|armadillo]\n")
    cat("  simple    - Switch to simple Rcpp version\n") 
    cat("  armadillo - Switch to RcppArmadillo version\n")
    return()
  }
  
  if (args[1] == "simple") {
    switch_to_simple()
  } else if (args[1] == "armadillo") {
    switch_to_armadillo()
  } else {
    cat("Invalid option. Use 'simple' or 'armadillo'\n")
  }
}

# Run if called directly
if (sys.nframe() == 0) {
  main()
}

# Also provide interactive functions
cat("Available functions:\n")
cat("  switch_to_simple()    - Switch to simple Rcpp version\n")
cat("  switch_to_armadillo() - Switch to RcppArmadillo version\n")