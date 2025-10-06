
#' Edge Component Assignment Alias
#'
#' Convenient alias for get_edge_components() that returns just the from_components
#' vector, which is the same length as the input edges. Perfect for the pattern:
#' group_id <- group_edges(edges)
#'
#' @param edges A two-column matrix or data.frame of edges
#' @param n_nodes Optional. Total number of nodes. If not provided, inferred from edges.
#' @param compress Logical. Whether to compress component IDs. Default is TRUE.
#'
#' @return Integer vector same length as nrow(edges), giving component ID for each edge's 'from' node
#'
#' @examples
#' edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
#' group_edges(edges)  # Returns c(1, 1, 2) - component of each from node
#'
#' @export  
group_edges <- function(edges, n_nodes = NULL, compress = TRUE) {
  get_edge_components(edges, n_nodes = n_nodes, compress = compress, return_type = "combined")
}
