#' Find Connected Components in Large Graphs (Large Integer Support)
#'
#' Enhanced version that handles large integers by mapping them to consecutive
#' small integers internally, then mapping results back.
#'
#' @param edges A two-column matrix or data.frame where each row represents an edge
#' @param compress Logical. Whether to compress component IDs. Default is TRUE.
#'
#' @return A list containing:
#' \item{components}{Named vector where names are original node IDs and values are component IDs}
#' \item{component_sizes}{Integer vector of component sizes}
#' \item{n_components}{Total number of connected components}
#' \item{node_mapping}{Data frame showing original to mapped ID conversion}
#'
#' @export
find_connected_components_large <- function(edges, compress = TRUE) {
  # Input validation
  if (!is.matrix(edges) && !is.data.frame(edges)) {
    stop("edges must be a matrix or data.frame")
  }
  
  if (ncol(edges) != 2) {
    stop("edges must have exactly 2 columns")
  }
  
  # Convert to matrix if data.frame
  if (is.data.frame(edges)) {
    edges <- as.matrix(edges)
  }
  
  # Keep as numeric to preserve large integers
  edges <- matrix(as.numeric(edges), ncol = 2)
  
  # Check for invalid values
  if (any(edges < 1, na.rm = TRUE)) {
    stop("All node IDs must be positive integers >= 1")
  }
  
  if (any(is.na(edges))) {
    stop("edges contains missing values (NA). Large integers may have overflowed - check your node IDs")
  }
  
  # Extract all unique node IDs
  all_nodes <- sort(unique(c(edges[, 1], edges[, 2])))
  n_nodes <- length(all_nodes)
  
  cat("Found", n_nodes, "unique nodes\n")
  cat("Node ID range:", min(all_nodes), "to", max(all_nodes), "\n")
  
  # Check if we need mapping for large integers
  max_safe_int <- .Machine$integer.max  # 2147483647
  needs_mapping <- any(all_nodes > max_safe_int)
  
  if (needs_mapping) {
    cat("Large integers detected - creating mapping\n")
    
    # Create mapping from original IDs to consecutive small integers
    node_mapping <- data.frame(
      original = all_nodes,
      mapped = 1:n_nodes
    )
    
    # Create lookup for fast conversion
    id_lookup <- setNames(node_mapping$mapped, node_mapping$original)
    
    # Map edges to small integers
    edges_mapped <- matrix(0L, nrow = nrow(edges), ncol = 2)
    edges_mapped[, 1] <- id_lookup[as.character(edges[, 1])]
    edges_mapped[, 2] <- id_lookup[as.character(edges[, 2])]
    
    # Call C++ function with mapped integers
    result <- find_components_cpp(edges_mapped, n_nodes, compress)
    
    # Map results back to original node IDs
    components_named <- setNames(result$components, node_mapping$original)
    
    return(list(
      components = components_named,
      component_sizes = result$component_sizes,
      n_components = result$n_components,
      node_mapping = node_mapping
    ))
    
  } else {
    cat("Node IDs are within safe integer range\n")
    
    # Can use original approach but need to handle the case where node IDs aren't consecutive
    min_node <- min(all_nodes)
    max_node <- max(all_nodes)
    
    if (min_node == 1 && max_node == n_nodes) {
      # Consecutive IDs starting from 1 - can use directly
      edges_int <- matrix(as.integer(edges), ncol = 2)
      result <- find_components_cpp(edges_int, n_nodes, compress)
      
      # Create named components vector
      components_named <- setNames(result$components, 1:n_nodes)
      
    } else {
      # Non-consecutive IDs - need mapping even though integers are small
      node_mapping <- data.frame(
        original = all_nodes,
        mapped = 1:n_nodes
      )
      
      id_lookup <- setNames(node_mapping$mapped, node_mapping$original)
      
      edges_mapped <- matrix(0L, nrow = nrow(edges), ncol = 2)
      edges_mapped[, 1] <- id_lookup[as.character(edges[, 1])]
      edges_mapped[, 2] <- id_lookup[as.character(edges[, 2])]
      
      result <- find_components_cpp(edges_mapped, n_nodes, compress)
      
      # Map results back
      components_named <- setNames(result$components, node_mapping$original)
      
      return(list(
        components = components_named,
        component_sizes = result$component_sizes,
        n_components = result$n_components,
        node_mapping = node_mapping
      ))
    }
    
    return(list(
      components = components_named,
      component_sizes = result$component_sizes,
      n_components = result$n_components
    ))
  }
}