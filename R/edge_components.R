
#' Simple Edge Component Assignment
#'
#' Streamlined function that takes a data.table and returns just the component vector.
#' Perfect for: dt[, component := edge_components(.SD, "from", "to")]
#'
#' @param dt A data.table or data.frame containing edge information  
#' @param from_col Character. Name of the column containing 'from' node IDs.
#' @param to_col Character. Name of the column containing 'to' node IDs.
#' @param compress Logical. Whether to compress component IDs. Default is TRUE.
#'
#' @return Integer vector same length as nrow(dt), giving component ID for each edge
#'
#' @examples
#' dt <- data.table(from = c(1,2,5), to = c(2,3,6))
#' dt[, component := edge_components(.SD, "from", "to")]
#' 
#' # Or with custom column names
#' dt2 <- data.table(source = c(1,2,5), target = c(2,3,6))
#' dt2[, group_id := edge_components(.SD, "source", "target")]
#'
#' @export
edge_components <- function(dt, from_col, to_col, compress = TRUE) {
  edges_matrix <- as.matrix(dt[, c(from_col, to_col), with = FALSE])
  group_edges(edges_matrix, compress = compress)
}
