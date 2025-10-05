#' Check if Two Nodes are Connected
#'
#' Efficiently checks if two nodes are in the same connected component.
#' This is much faster than computing all components when you only need
#' to check specific pairs.
#'
#' @param edges A two-column matrix or data.frame representing graph edges
#' @param query_pairs A two-column matrix of node pairs to check for connectivity
#' @param n_nodes Optional. Total number of nodes in the graph.
#'
#' @return Logical vector indicating whether each query pair is connected
#'
#' @examples
#' edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
#' queries <- matrix(c(1,3, 1,5, 5,6), ncol=2, byrow=TRUE)
#' are_connected(edges, queries)  # Returns c(TRUE, FALSE, TRUE)
#'
#' @export
are_connected <- function(edges, query_pairs, n_nodes = NULL) {
  # Input validation
  if (!is.matrix(edges) && !is.data.frame(edges)) {
    stop("edges must be a matrix or data.frame")
  }
  
  if (!is.matrix(query_pairs) && !is.data.frame(query_pairs)) {
    stop("query_pairs must be a matrix or data.frame")
  }
  
  if (ncol(edges) != 2 || ncol(query_pairs) != 2) {
    stop("Both edges and query_pairs must have exactly 2 columns")
  }
  
  # Convert to matrices
  edges <- matrix(as.integer(edges), ncol = 2)
  query_pairs <- matrix(as.integer(query_pairs), ncol = 2)
  
  # Determine number of nodes
  if (is.null(n_nodes)) {
    n_nodes <- max(c(edges, query_pairs))
  } else {
    n_nodes <- as.integer(n_nodes)
  }
  
  # Call C++ function
  result <- are_connected_cpp(edges, query_pairs, n_nodes)
  
  return(result)
}
