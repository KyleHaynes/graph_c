#!/usr/bin/env Rscript
# Example usage of graphfast package for large-scale graph analysis

library(graphfast)

cat("=== GraphFast Package Demo ===\n\n")

# Configuration for massive scale testing
MASSIVE_SCALE <- TRUE  # Set to FALSE for quick demo with small graphs

if (MASSIVE_SCALE) {
  cat("🚀 MASSIVE SCALE MODE: Generating 40 million edges\n")
  cat("⚠️  WARNING: This will use significant memory and processing time!\n")
  cat("   Expected: 5-15 minutes generation + 1-5 minutes analysis\n")
  cat("   Memory: 2-8 GB RAM recommended\n")
  cat("   Set MASSIVE_SCALE <- FALSE for quick demo\n\n")
  
  # Ask for confirmation in interactive mode
  if (interactive()) {
    response <- readline("Continue with massive scale test? (y/N): ")
    if (tolower(substr(response, 1, 1)) != "y") {
      cat("Switching to quick demo mode...\n")
      MASSIVE_SCALE <- FALSE
    }
  }
}

# Example 1: Connected Components Analysis
cat("1. Finding Connected Components\n")
cat("==============================\n")

if (MASSIVE_SCALE) {
  # Create a massive graph with 40 million edges for performance testing
  cat("Generating massive graph with 40 million edges...\n")
  cat("This may take a few minutes...\n")

  # Parameters for large-scale graph generation
  n_edges_target <- 40000000  # 40 million edges
  n_nodes <- 10000000         # 10 million nodes
  n_components <- 1000        # Create 1000 separate components

  # Generate a large-scale graph with multiple components
  generate_massive_graph <- function(n_edges, n_nodes, n_components) {
    # Calculate edges per component
    edges_per_component <- n_edges %/% n_components
    nodes_per_component <- n_nodes %/% n_components
    
    cat("Creating", n_components, "components with ~", edges_per_component, "edges each\n")
    
    # Pre-allocate the matrix for efficiency
    edges_matrix <- matrix(0L, nrow = n_edges, ncol = 2)
    current_row <- 1
    
    for (comp in 1:n_components) {
      # Node range for this component
      start_node <- (comp - 1) * nodes_per_component + 1
      end_node <- min(comp * nodes_per_component, n_nodes)
      component_nodes <- start_node:end_node
      
      # Generate edges for this component
      component_edge_count <- if (comp == n_components) {
        # Last component gets remaining edges
        n_edges - current_row + 1
      } else {
        edges_per_component
      }
      
      if (component_edge_count > 0) {
        # Create a mix of structured and random connections
        # 1. Chain structure (ensures connectivity)
        chain_edges <- min(length(component_nodes) - 1, component_edge_count %/% 4)
        if (chain_edges > 0) {
          chain_from <- component_nodes[1:(chain_edges)]
          chain_to <- component_nodes[2:(chain_edges + 1)]
          
          end_row <- current_row + chain_edges - 1
          edges_matrix[current_row:end_row, 1] <- chain_from
          edges_matrix[current_row:end_row, 2] <- chain_to
          current_row <- end_row + 1
          component_edge_count <- component_edge_count - chain_edges
        }
        
        # 2. Random edges within component
        if (component_edge_count > 0) {
          random_from <- sample(component_nodes, component_edge_count, replace = TRUE)
          random_to <- sample(component_nodes, component_edge_count, replace = TRUE)
          
          # Remove self-loops
          valid_edges <- random_from != random_to
          random_from <- random_from[valid_edges]
          random_to <- random_to[valid_edges]
          
          if (length(random_from) > 0) {
            end_row <- current_row + length(random_from) - 1
            if (end_row <= n_edges) {
              edges_matrix[current_row:end_row, 1] <- random_from
              edges_matrix[current_row:end_row, 2] <- random_to
              current_row <- end_row + 1
            }
          }
        }
      }
      
      # Progress indicator
      if (comp %% 100 == 0) {
        cat("Generated", comp, "/", n_components, "components\n")
      }
    }
    
    # Trim matrix to actual size
    actual_edges <- current_row - 1
    if (actual_edges < n_edges) {
      edges_matrix <- edges_matrix[1:actual_edges, , drop = FALSE]
    }
    
    return(edges_matrix)
  }

  # Generate the massive graph
  start_gen_time <- Sys.time()
  edges1 <- generate_massive_graph(n_edges_target, n_nodes, n_components)
  end_gen_time <- Sys.time()

  cat("Generated", nrow(edges1), "edges in", 
      round(as.numeric(end_gen_time - start_gen_time), 2), "seconds\n")
  cat("Graph spans", max(edges1), "nodes across", n_components, "components\n")

} else {
  # Quick demo with small graph
  cat("Quick demo mode: Creating small graph for demonstration\n")
  edges1 <- matrix(c(
    1, 2,  # Component 1: nodes 1-4
    2, 3,
    3, 4,
    5, 6,  # Component 2: nodes 5-6
    8, 9,  # Component 3: nodes 8-10
    9, 10
  ), ncol = 2, byrow = TRUE)
  
  cat("Created simple graph with", nrow(edges1), "edges\n")
}

if (MASSIVE_SCALE) {
  cat("Testing connected components on massive graph...\n")
  cat("Monitoring memory usage...\n")

  # Memory before processing
  gc_before <- gc()
  mem_before_mb <- sum(gc_before[, "used"] * c(gc_before[1, "max"], 8)) / 1024^2

  start_time <- Sys.time()
  result1 <- find_connected_components(edges1)
  end_time <- Sys.time()

  # Memory after processing
  gc_after <- gc()
  mem_after_mb <- sum(gc_after[, "used"] * c(gc_after[1, "max"], 8)) / 1024^2
  mem_used_mb <- mem_after_mb - mem_before_mb

  cat("MASSIVE GRAPH ANALYSIS RESULTS:\n")
  cat("===============================\n")
  cat("Graph with", nrow(edges1), "edges\n")
  cat("Number of components:", result1$n_components, "\n")
  cat("Processing time:", round(as.numeric(end_time - start_time), 3), "seconds\n")
  cat("Edges per second:", round(nrow(edges1) / as.numeric(end_time - start_time), 0), "\n")
  cat("Memory used:", round(mem_used_mb, 1), "MB\n")
  cat("Memory per edge:", round(mem_used_mb * 1024 / nrow(edges1), 3), "KB per edge\n")

  # Show top 10 largest components instead of all sizes
  sorted_sizes <- sort(result1$component_sizes, decreasing = TRUE)
  cat("Top 10 component sizes:", paste(head(sorted_sizes, 10), collapse = ", "), "\n")
  cat("Smallest components:", paste(tail(sorted_sizes, 5), collapse = ", "), "\n")

  # Don't print all node assignments for 40M edges - just summary
  cat("Total nodes processed:", length(result1$components), "\n")
  cat("Memory efficiency: Processing", round(nrow(edges1)/1000000, 1), "million edges\n\n")

} else {
  # Standard demo output for small graphs
  result1 <- find_connected_components(edges1)
  cat("Graph with", nrow(edges1), "edges\n")
  cat("Number of components:", result1$n_components, "\n")
  cat("Component sizes:", paste(result1$component_sizes, collapse = ", "), "\n")
  cat("Node assignments:", paste(result1$components, collapse = ", "), "\n\n")
}

# Example 2: Connectivity Queries
cat("2. Checking Node Connectivity\n")
cat("=============================\n")

query_pairs <- matrix(c(
  1, 4,  # Should be connected (same component)
  1, 5,  # Should NOT be connected (different components)
  5, 6,  # Should be connected
  8, 10  # Should be connected
), ncol = 2, byrow = TRUE)

connectivity_result <- are_connected(edges1, query_pairs)
for (i in 1:nrow(query_pairs)) {
  cat("Nodes", query_pairs[i,1], "and", query_pairs[i,2], "are", 
      if(connectivity_result[i]) "CONNECTED" else "NOT CONNECTED", "\n")
}
cat("\n")

# Example 3: Shortest Paths
cat("3. Computing Shortest Paths\n")
cat("===========================\n")

path_queries <- matrix(c(
  1, 4,  # Path length should be 3
  1, 5,  # No path (different components)
  8, 10  # Path length should be 2
), ncol = 2, byrow = TRUE)

distances <- shortest_paths(edges1, path_queries)
for (i in 1:nrow(path_queries)) {
  dist_str <- if(distances[i] == -1) "No path" else paste("Distance:", distances[i])
  cat("From node", path_queries[i,1], "to node", path_queries[i,2], "->", dist_str, "\n")
}
cat("\n")

# Example 4: Graph Statistics
cat("4. Graph Statistics\n")
cat("===================\n")

stats <- graph_statistics(edges1)
cat("Number of edges:", stats$n_edges, "\n")
cat("Number of nodes:", stats$n_nodes, "\n")
cat("Graph density:", round(stats$density, 4), "\n")
cat("Degree statistics:\n")
cat("  Min degree:", stats$degree_stats$min, "\n")
cat("  Max degree:", stats$degree_stats$max, "\n")
cat("  Mean degree:", round(stats$degree_stats$mean, 2), "\n\n")

# Example 5: Large Graph Performance Test
cat("5. Large Graph Performance Test\n")
cat("===============================\n")

# Generate a larger random graph for performance testing
set.seed(42)
n_nodes_large <- 50000
n_edges_large <- 100000

cat("Generating random graph with", n_nodes_large, "nodes and", n_edges_large, "edges...\n")
large_edges <- matrix(sample(1:n_nodes_large, 2 * n_edges_large, replace = TRUE), ncol = 2)

# Remove self-loops
large_edges <- large_edges[large_edges[,1] != large_edges[,2], ]

cat("Testing connected components on large graph...\n")
start_time <- Sys.time()
large_result <- find_connected_components(large_edges, n_nodes = n_nodes_large)
end_time <- Sys.time()

cat("Completed in", round(as.numeric(end_time - start_time), 3), "seconds\n")
cat("Found", large_result$n_components, "connected components\n")
cat("Largest component size:", max(large_result$component_sizes), "\n\n")

# Example 6: Real-world Use Case Simulation
cat("6. Social Network Analysis Simulation\n")
cat("=====================================\n")

# Simulate a social network with communities
generate_community_graph <- function(n_communities, community_size, inter_community_edges) {
  edges <- matrix(nrow = 0, ncol = 2)
  
  # Generate intra-community edges (dense connections within communities)
  for (i in 1:n_communities) {
    start_node <- (i - 1) * community_size + 1
    end_node <- i * community_size
    
    # Create a random graph within each community
    community_nodes <- start_node:end_node
    n_intra_edges <- community_size * 2  # Average degree of 4 within community
    
    intra_edges <- matrix(sample(community_nodes, 2 * n_intra_edges, replace = TRUE), ncol = 2)
    intra_edges <- intra_edges[intra_edges[,1] != intra_edges[,2], ]  # Remove self-loops
    edges <- rbind(edges, intra_edges)
  }
  
  # Add inter-community edges (sparse connections between communities)
  for (i in 1:inter_community_edges) {
    comm1 <- sample(1:n_communities, 1)
    comm2 <- sample(1:n_communities, 1)
    if (comm1 != comm2) {
      node1 <- (comm1 - 1) * community_size + sample(1:community_size, 1)
      node2 <- (comm2 - 1) * community_size + sample(1:community_size, 1)
      edges <- rbind(edges, c(node1, node2))
    }
  }
  
  return(unique(edges))  # Remove duplicate edges
}

social_edges <- generate_community_graph(n_communities = 10, community_size = 100, inter_community_edges = 50)
cat("Generated social network with", nrow(social_edges), "edges\n")

social_components <- find_connected_components(social_edges)
cat("Detected", social_components$n_components, "communities\n")

# Analyze community structure
sorted_sizes <- sort(social_components$component_sizes, decreasing = TRUE)
cat("Top 5 community sizes:", paste(head(sorted_sizes, 5), collapse = ", "), "\n")

# Test influence propagation (shortest paths from influential nodes)
influential_nodes <- c(50, 150, 250)  # Nodes from different communities
target_nodes <- sample(1:1000, 10)    # Random target nodes

influence_queries <- expand.grid(influential_nodes, target_nodes)
colnames(influence_queries) <- c("from", "to")
influence_queries <- as.matrix(influence_queries)

cat("Computing influence distances from", length(influential_nodes), "influential nodes to", 
    length(target_nodes), "targets...\n")
influence_distances <- shortest_paths(social_edges, influence_queries)

# Summarize results
reachable <- sum(influence_distances != -1)
avg_distance <- mean(influence_distances[influence_distances != -1])
cat("Reachable targets:", reachable, "out of", length(influence_distances), "\n")
cat("Average distance to reachable targets:", round(avg_distance, 2), "\n\n")

# Example 7: Memory Efficiency Demonstration
cat("7. Memory Efficiency Demonstration\n")
cat("==================================\n")

# Show memory usage comparison
cat("Memory usage analysis:\n")

# Small graph memory usage
small_edges <- matrix(sample(1:1000, 2000, replace = TRUE), ncol = 2)
mem_before <- gc()["Vcells", "used"] * 8  # Rough memory estimate

small_result <- find_connected_components(small_edges)
mem_after <- gc()["Vcells", "used"] * 8

cat("Small graph (1000 edges): ~", round((mem_after - mem_before) / 1024, 2), "KB additional memory\n")

# The algorithm uses O(n + m) memory, not O(n²) like adjacency matrices
max_nodes <- max(small_edges)
adjacency_matrix_memory <- max_nodes^2 * 8 / 1024  # Bytes to KB
cat("Equivalent adjacency matrix would use: ~", round(adjacency_matrix_memory, 2), "KB\n")
cat("Memory savings: ~", round(adjacency_matrix_memory / ((mem_after - mem_before) / 1024), 1), "x\n\n")

cat("=== Demo Complete ===\n")
cat("The graphfast package provides efficient algorithms for:\n")
cat("- Connected components analysis\n")
cat("- Pairwise connectivity queries\n")  
cat("- Shortest path computations\n")
cat("- Graph statistics\n")
cat("- Memory-efficient processing of large graphs\n\n")
cat("For more information, see the package documentation and README.\n")