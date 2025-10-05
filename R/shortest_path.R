
#' Find Shortest Paths Between Node Pairs
#'
#' Computes shortest paths between specified pairs of nodes using BFS.
#' Optimized for multiple queries on the same graph.
#'
#' @param edges A two-column matrix or data.frame representing graph edges
#' @param query_pairs A two-column matrix of source-target node pairs
#' @param n_nodes Optional. Total number of nodes in the graph.
#' @param max_distance Maximum distance to search. Paths longer than this
#'   will return -1. Default is -1 (no limit).
#'
#' @return Integer vector of shortest path distances. Returns -1 if no path exists
#'   or if distance exceeds max_distance.
#'
#' @examples
#' edges <- matrix(c(1,2, 2,3, 3,4), ncol=2, byrow=TRUE)
#' queries <- matrix(c(1,4, 1,5), ncol=2, byrow=TRUE)
#' shortest_paths(edges, queries)  # Returns c(3, -1)
#'
#' @export
shortest_paths <- function(edges, query_pairs, n_nodes = NULL, max_distance = -1) {
  # Input validation (similar to above functions)
  edges <- matrix(as.integer(edges), ncol = 2)
  query_pairs <- matrix(as.integer(query_pairs), ncol = 2)
  
  if (is.null(n_nodes)) {
    n_nodes <- max(c(edges, query_pairs))
  } else {
    n_nodes <- as.integer(n_nodes)
  }
  
  max_distance <- as.integer(max_distance)
  
  # Call C++ function
  result <- shortest_paths_cpp(edges, query_pairs, n_nodes, max_distance)
  
  return(result)
}
