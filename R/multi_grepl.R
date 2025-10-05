
#' Multi-Pattern String Matching
#'
#' Fast multi-pattern string matching using C++. Similar to applying
#' grepl(pattern, x, fixed=TRUE) for multiple patterns, but much faster.
#'
#' @param strings Character vector of strings to search in
#' @param patterns Character vector of fixed patterns to search for
#' @param match_any Logical. If TRUE (default), returns TRUE if ANY pattern matches.
#'   If FALSE, returns detailed results for each pattern.
#' @param ignore_case Logical. Whether to ignore case when matching. Default FALSE.
#' @param return_matrix Logical. If TRUE and match_any=FALSE, returns a matrix.
#'   If FALSE and match_any=FALSE, returns a data.frame. Default FALSE.
#'
#' @return If match_any=TRUE: Logical vector same length as strings.
#'   If match_any=FALSE: Matrix or data.frame showing which patterns match which strings.
#'
#' @examples
#' strings <- c("hello world", "goodbye", "hello there", "world peace")
#' patterns <- c("hello", "world")
#' 
#' # Check if any pattern matches each string
#' multi_grepl(strings, patterns)
#' 
#' # Get detailed results
#' multi_grepl(strings, patterns, match_any = FALSE)
#' 
#' # Case insensitive matching
#' multi_grepl(c("Hello", "WORLD"), c("hello", "world"), ignore_case = TRUE)
#'
#' @export
multi_grepl <- function(strings, patterns, match_any = TRUE, ignore_case = FALSE, return_matrix = FALSE) {
  
  # Input validation
  if (!is.character(strings)) {
    stop("strings must be a character vector")
  }
  
  if (!is.character(patterns)) {
    stop("patterns must be a character vector")
  }
  
  if (length(patterns) == 0) {
    if (match_any) {
      return(rep(FALSE, length(strings)))
    } else {
      return(matrix(FALSE, nrow = length(strings), ncol = 0))
    }
  }
  
  if (match_any) {
    # Use optimized single-vector version
    return(multi_grepl_any_cpp(strings, patterns, ignore_case))
  } else {
    # Use matrix version
    result_matrix <- multi_grepl_cpp(strings, patterns, match_any = FALSE, ignore_case)
    
    if (return_matrix) {
      # Add row and column names
      rownames(result_matrix) <- paste0("string_", seq_len(nrow(result_matrix)))
      colnames(result_matrix) <- patterns
      return(result_matrix)
    } else {
      # Convert to data.frame with better column names
      result_df <- as.data.frame(result_matrix)
      colnames(result_df) <- patterns
      rownames(result_df) <- NULL
      return(result_df)
    }
  }
}