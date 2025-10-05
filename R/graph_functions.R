#' Find Connected Components in Large Graphs
#'
#' Efficiently finds all connected components in a graph represented by edge pairs.
#' Uses optimized C++ algorithms with Union-Find data structure for handling
#' hundreds of millions of edges.
#'
#' @param edges A two-column matrix or data.frame where each row represents an edge
#'   between two nodes. Nodes should be represented as integers starting from 1.
#' @param n_nodes Optional. Total number of nodes in the graph. If not provided,
#'   will be inferred from the maximum node ID in edges.
#' @param compress Logical. Whether to compress node IDs to consecutive integers.
#'   Useful when node IDs are sparse. Default is TRUE.
#'
#' @return A list containing:
#' \item{components}{Integer vector where each element represents the component ID
#'   for the corresponding node}
#' \item{component_sizes}{Integer vector of component sizes}
#' \item{n_components}{Total number of connected components}
#'
#' @examples
#' # Create a simple graph with 3 components
#' edges <- matrix(c(1,2, 2,3, 5,6, 8,9, 9,10), ncol=2, byrow=TRUE)
#' result <- find_connected_components(edges)
#' print(result$n_components)  # Should be 3
#'
#' @export
find_connected_components <- function(edges, n_nodes = NULL, compress = TRUE) {
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
  
  # Check for large integers before conversion
  edges_numeric <- matrix(as.numeric(edges), ncol = 2)
  max_safe_int <- .Machine$integer.max  # 2,147,483,647
  
  if (any(edges_numeric > max_safe_int, na.rm = TRUE)) {
    large_vals <- unique(edges_numeric[edges_numeric > max_safe_int & !is.na(edges_numeric)])
    stop("Node IDs exceed 32-bit integer limit (", max_safe_int, "). ",
         "Large values found: ", paste(head(large_vals, 3), collapse = ", "), 
         if(length(large_vals) > 3) "..." else "", ". ",
         "Use find_connected_components_large() for large integer support or ",
         "remap your node IDs to smaller consecutive integers.")
  }
  
  # Convert to integer (safe now)
  edges <- matrix(as.integer(edges_numeric), ncol = 2)
  
  # Check for invalid values
  if (any(edges < 1, na.rm = TRUE)) {
    stop("All node IDs must be positive integers >= 1")
  }
  
  if (any(is.na(edges))) {
    stop("edges contains NA values. This may indicate integer overflow from large node IDs.")
  }
  
  # Determine number of nodes
  if (is.null(n_nodes)) {
    n_nodes <- max(edges)
  } else {
    n_nodes <- as.integer(n_nodes)
    if (n_nodes < max(edges)) {
      stop("n_nodes must be at least as large as the maximum node ID in edges")
    }
  }
  
  # Memory safety check
  unique_nodes <- length(unique(c(edges[, 1], edges[, 2])))
  estimated_memory_gb <- n_nodes * 12 / 1024^3  # Rough estimate
  
  if (estimated_memory_gb > 8) {  # Warning for >8GB allocation
    warning("Large memory allocation required (~", round(estimated_memory_gb, 1), 
            "GB) due to sparse node IDs.\n",
            "Consider using find_connected_components_safe() which automatically ",
            "remaps node IDs.\n",
            "Unique nodes: ", unique_nodes, ", Max node ID: ", n_nodes)
  }
  
  if (estimated_memory_gb > 32) {  # Hard stop for >32GB
    stop("Memory allocation would exceed 32GB (", round(estimated_memory_gb, 1), 
         "GB) due to sparse large node IDs.\n",
         "Use find_connected_components_safe() instead, which handles large sparse node IDs efficiently.\n",
         "Your graph has ", unique_nodes, " unique nodes but max ID is ", n_nodes)
  }
  
  # Call C++ function
  result <- find_components_cpp(edges, n_nodes, compress)
  
  return(result)
}

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

#' Get Edge Component Assignments
#'
#' Efficiently returns component assignments for each edge in the input.
#' This is much faster than computing connected components separately and 
#' then doing lookups in R.
#'
#' @param edges A two-column matrix or data.frame where each row represents an edge
#' @param n_nodes Optional. Total number of nodes. If not provided, inferred from edges.
#' @param compress Logical. Whether to compress component IDs. Default is TRUE.
#' @param return_type Character. Either "list" (default) for separate from/to vectors,
#'   or "combined" for a single vector of from components only.
#'
#' @return If return_type="list": List with from_components, to_components, n_components.
#'   If return_type="combined": Integer vector of from_components (same length as input edges).
#'
#' @examples
#' edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
#' result <- get_edge_components(edges)
#' # result$from_components gives component ID for each 'from' node
#' # result$to_components gives component ID for each 'to' node
#'
#' # For your specific use case:
#' group_ids <- get_edge_components(edges, return_type = "combined")
#' # group_ids is same length as nrow(edges), gives component of 'from' node
#'
#' @export
get_edge_components <- function(edges, n_nodes = NULL, compress = TRUE, return_type = "list") {
  # Input validation (same as find_connected_components)
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
  
  # Check for large integers before conversion
  edges_numeric <- matrix(as.numeric(edges), ncol = 2)
  max_safe_int <- .Machine$integer.max  # 2,147,483,647
  
  if (any(edges_numeric > max_safe_int, na.rm = TRUE)) {
    large_vals <- unique(edges_numeric[edges_numeric > max_safe_int & !is.na(edges_numeric)])
    stop("Node IDs exceed 32-bit integer limit (", max_safe_int, "). ",
         "Large values found: ", paste(head(large_vals, 3), collapse = ", "), 
         if(length(large_vals) > 3) "..." else "", ". ",
         "Use get_edge_components_safe() for large integer support or ",
         "remap your node IDs to smaller consecutive integers.")
  }
  
  # Convert to integer (safe now)
  edges <- matrix(as.integer(edges_numeric), ncol = 2)
  
  # Check for invalid values
  if (any(edges < 1, na.rm = TRUE)) {
    stop("All node IDs must be positive integers >= 1")
  }
  
  if (any(is.na(edges))) {
    stop("edges contains NA values. This may indicate integer overflow from large node IDs.")
  }
  
  # Determine number of nodes with memory safety check
  if (is.null(n_nodes)) {
    n_nodes <- max(edges)
  } else {
    n_nodes <- as.integer(n_nodes)
    if (n_nodes < max(edges)) {
      stop("n_nodes must be at least as large as the maximum node ID in edges")
    }
  }
  
  # Memory safety check
  unique_nodes <- length(unique(c(edges[, 1], edges[, 2])))
  estimated_memory_gb <- n_nodes * 12 / 1024^3
  
  if (estimated_memory_gb > 8) {
    warning("Large memory allocation required (~", round(estimated_memory_gb, 1), 
            "GB) due to sparse node IDs.\n",
            "Consider using get_edge_components_safe() which automatically ",
            "remaps node IDs.\n",
            "Unique nodes: ", unique_nodes, ", Max node ID: ", n_nodes)
  }
  
  if (estimated_memory_gb > 32) {
    stop("Memory allocation would exceed 32GB (", round(estimated_memory_gb, 1), 
         "GB) due to sparse large node IDs.\n",
         "Use get_edge_components_safe() instead.\n",
         "Your graph has ", unique_nodes, " unique nodes but max ID is ", n_nodes)
  }
  
  # Call C++ function
  result <- get_edge_components_cpp(edges, n_nodes, compress)
  
  # Return based on requested type
  if (return_type == "combined") {
    return(result$from_components)
  } else if (return_type == "list") {
    return(result)
  } else {
    stop("return_type must be either 'list' or 'combined'")
  }
}

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
#' group_id <- group_edges(edges)  # Returns c(1, 1, 2) - component of each from node
#'
#' @export  
group_edges <- function(edges, n_nodes = NULL, compress = TRUE) {
  get_edge_components(edges, n_nodes = n_nodes, compress = compress, return_type = "combined")
}

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
#' dt <- data.table(source = c(1,2,5), target = c(2,3,6), weight = c(0.5, 0.8, 0.3))
#' 
#' # Add component column (modifies dt in place)
#' add_component_column(dt, from_col = "source", to_col = "target")
#' # Now dt has a 'component' column
#' 
#' # Or specify custom column name and don't modify original
#' dt2 <- add_component_column(dt, component_col = "group_id", in_place = FALSE)
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
    return(invisible(dt))
  } else {
    # Return a copy
    dt_copy <- copy(dt)
    dt_copy[, (component_col) := component_ids]
    return(dt_copy)
  }
}

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