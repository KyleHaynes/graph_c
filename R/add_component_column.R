
#' Add Component Column to Data.Table
#'
#' Efficiently adds a component ID column directly to an existing data.table.
#' You can specify which columns represent the edges (from/to nodes).
#' Since edges connect nodes in the same component, only one component ID per edge is needed.
#'
#' @param dt A data.table containing edge information
#' @param from_col Character. Name of the column containing 'from' node IDs. Default "from".
#' @param to_col Character. Name of the column containing 'to' node IDs. Default "to".
#' @param component_col Character. Name for the new component column. Default "component".
#' @param n_nodes Optional. Total number of nodes. If not provided, inferred from data.
#' @param compress Logical. Whether to compress component IDs. Default is TRUE.
#' @param in_place Logical. Whether to modify the data.table in place (TRUE) or return a copy (FALSE). Default TRUE.
#'
#' @return If in_place=TRUE, modifies dt and returns it invisibly. If in_place=FALSE, returns a copy of dt with the new column.
#'
#' @examples
#' # Create a data.table with edges
#' require("data.table")
#' dt <- data.table(source = c(1,2,5), target = c(2,3,6), weight = c(0.5, 0.8, 0.3))
#' dt
#' 
#' # Add component column (modifies dt in place)
#' add_component_column(dt, from_col = "source", to_col = "target")
#' # Now dt has a 'component' column
#' 
#' # Or specify custom column name and don't modify original
#' dt2 <- add_component_column(dt, from_col = "source", to_col = "target",component_col = "group_id", in_place = FALSE)
#' dt2
#' 
#' @export
add_component_column <- function(dt, from_col = "from", to_col = "to", 
                                component_col = "component", n_nodes = NULL, 
                                compress = TRUE, in_place = TRUE) {
  
  # Input validation
  if (!is.data.table(dt)) {
    stop("dt must be a data.table")
  }
  
  if (!from_col %in% names(dt)) {
    stop("Column '", from_col, "' not found in data.table")
  }
  
  if (!to_col %in% names(dt)) {
    stop("Column '", to_col, "' not found in data.table")
  }
  
  if (component_col %in% names(dt)) {
    warning("Column '", component_col, "' already exists and will be overwritten")
  }
  
  # Extract edge matrix
  edges_matrix <- as.matrix(dt[, c(from_col, to_col), with = FALSE])
  
  # Get component IDs for each edge
  component_ids <- group_edges(edges_matrix, n_nodes = n_nodes, compress = compress)
  
  # Add to data.table
  if (in_place) {
    # Modify in place
    dt[, (component_col) := component_ids]
    return(invisible(dt[]))
  } else {
    # Return a copy
    dt_copy <- copy(dt)
    dt_copy[, (component_col) := component_ids]
    return(dt_copy[])
  }
}
