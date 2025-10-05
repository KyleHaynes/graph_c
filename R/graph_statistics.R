
#' Memory-Efficient Graph Statistics
#'
#' Computes basic graph statistics without storing the full adjacency structure.
#' Useful for very large graphs where memory is constrained.
#'
#' @param edges A two-column matrix or data.frame representing graph edges
#' @param n_nodes Optional. Total number of nodes in the graph.
#'
#' @return A list containing:
#' \item{n_edges}{Number of edges}
#' \item{n_nodes}{Number of nodes}
#' \item{density}{Graph density}
#' \item{degree_stats}{Summary statistics of node degrees}
#'
#' @export
graph_statistics <- function(edges, n_nodes = NULL) {
  edges <- matrix(as.integer(edges), ncol = 2)
  
  if (is.null(n_nodes)) {
    n_nodes <- max(edges)
  } else {
    n_nodes <- as.integer(n_nodes)
  }
  
  # Call C++ function
  result <- graph_stats_cpp(edges, n_nodes)
  
  return(result)
}
