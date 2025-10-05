#' Fast String Filtering
#'
#' Efficiently filter strings that contain any of the specified patterns.
#' Equivalent to strings[grepl(pattern1, strings, fixed=TRUE) | grepl(pattern2, strings, fixed=TRUE) | ...]
#' but much faster for multiple patterns.
#'
#' @param strings Character vector of strings to filter
#' @param patterns Character vector of patterns to search for
#' @param ignore_case Logical. Whether to ignore case. Default FALSE.
#' @param invert Logical. If TRUE, return strings that do NOT match any pattern. Default FALSE.
#'
#' @return Character vector of strings that match (or don't match if invert=TRUE) any pattern
#'
#' @examples
#' strings <- c("apple pie", "banana bread", "cherry tart", "date cake")
#' patterns <- c("apple", "cherry")
#' 
#' # Get strings containing any pattern
#' filter_strings(strings, patterns)
#' # Returns: "apple pie" "cherry tart"
#' 
#' # Get strings NOT containing any pattern
#' filter_strings(strings, patterns, invert = TRUE)
#' # Returns: "banana bread" "date cake"
#'
#' @export
filter_strings <- function(strings, patterns, ignore_case = FALSE, invert = FALSE) {
  matches <- multi_grepl(strings, patterns, match_any = TRUE, ignore_case = ignore_case)
  
  if (invert) {
    return(strings[!matches])
  } else {
    return(strings[matches])
  }
}
