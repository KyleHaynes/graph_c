#!/usr/bin/env Rscript
# GraphFast Performance Test with Scalable Graph Size
# Usage: Rscript performance_test.R [n_edges_millions] [n_components]

library(graphfast)

# Parse command line arguments or use defaults
args <- commandArgs(trailingOnly = TRUE)
n_edges_millions <- if(length(args) >= 1) as.numeric(args[1]) else 1  # Default 40M edges
n_components <- if(length(args) >= 2) as.numeric(args[2]) else 1000    # Default 1000 components

cat("=== GraphFast Massive Scale Performance Test ===\n")
cat("Target edges:", n_edges_millions, "million\n")
cat("Target components:", n_components, "\n\n")

# Calculate derived parameters
n_edges_target <- n_edges_millions * 1000000
n_nodes <- n_edges_target / 4  # Reasonable node-to-edge ratio
edges_per_component <- n_edges_target %/% n_components
nodes_per_component <- n_nodes %/% n_components

cat("Graph parameters:\n")
cat("- Edges:", n_edges_target, "\n")
cat("- Nodes:", n_nodes, "\n")
cat("- Components:", n_components, "\n")
cat("- Avg edges per component:", edges_per_component, "\n")
cat("- Avg nodes per component:", nodes_per_component, "\n\n")

# Efficient massive graph generator
generate_scalable_graph <- function(n_edges, n_nodes, n_components) {
  cat("Generating massive graph...\n")
  
  # Use efficient memory allocation
  edges_matrix <- matrix(0L, nrow = n_edges, ncol = 2)
  current_row <- 1
  
  edges_per_comp <- n_edges %/% n_components
  nodes_per_comp <- n_nodes %/% n_components
  
  for (comp in 1:n_components) {
    # Calculate node range for this component
    start_node <- (comp - 1) * nodes_per_comp + 1L
    end_node <- min(comp * nodes_per_comp, n_nodes)
    
    # Determine number of edges for this component
    comp_edges <- if (comp == n_components) {
      n_edges - current_row + 1  # Last component gets remaining edges
    } else {
      edges_per_comp
    }
    
    if (comp_edges > 0 && start_node <= end_node) {
      # Generate edges efficiently
      # Strategy: Create a connected component with additional random edges
      
      # 1. Ensure connectivity with a spanning tree
      tree_edges <- min(end_node - start_node, comp_edges %/% 3)
      if (tree_edges > 0) {
        from_nodes <- seq(start_node, start_node + tree_edges - 1)
        to_nodes <- seq(start_node + 1, start_node + tree_edges)
        
        end_row <- current_row + tree_edges - 1
        edges_matrix[current_row:end_row, 1] <- from_nodes
        edges_matrix[current_row:end_row, 2] <- to_nodes
        current_row <- end_row + 1
        comp_edges <- comp_edges - tree_edges
      }
      
      # 2. Add random edges within component
      if (comp_edges > 0) {
        # Batch generate random edges
        from_nodes <- sample(start_node:end_node, comp_edges, replace = TRUE)
        to_nodes <- sample(start_node:end_node, comp_edges, replace = TRUE)
        
        # Remove self-loops efficiently
        valid_mask <- from_nodes != to_nodes
        from_nodes <- from_nodes[valid_mask]
        to_nodes <- to_nodes[valid_mask]
        
        valid_count <- length(from_nodes)
        if (valid_count > 0) {
          end_row <- min(current_row + valid_count - 1, n_edges)
          actual_count <- end_row - current_row + 1
          
          edges_matrix[current_row:end_row, 1] <- from_nodes[1:actual_count]
          edges_matrix[current_row:end_row, 2] <- to_nodes[1:actual_count]
          current_row <- end_row + 1
        }
      }
    }
    
    # Progress reporting
    if (comp %% 50 == 0) {
      progress <- round(100 * comp / n_components, 1)
      cat("Progress:", progress, "% (", comp, "/", n_components, "components)\n")
    }
  }
  
  # Trim to actual size
  actual_size <- min(current_row - 1, n_edges)
  if (actual_size < n_edges) {
    edges_matrix <- edges_matrix[1:actual_size, , drop = FALSE]
  }
  
  return(edges_matrix)
}

# Generate the graph
cat("=== GRAPH GENERATION ===\n")
gen_start <- Sys.time()
edges <- generate_scalable_graph(n_edges_target, n_nodes, n_components)
gen_end <- Sys.time()
gen_time <- as.numeric(gen_end - gen_start)

cat("✓ Generated", nrow(edges), "edges in", round(gen_time, 2), "seconds\n")
cat("✓ Generation rate:", round(nrow(edges) / gen_time / 1000000, 2), "million edges/second\n")
cat("✓ Graph spans", max(edges), "nodes\n\n")

# Analyze connected components
cat("=== CONNECTED COMPONENTS ANALYSIS ===\n")
cat("Starting analysis of", nrow(edges), "edges...\n")

# Memory monitoring
gc_before <- gc(verbose = FALSE)
mem_before <- sum(gc_before[, "used"] * c(gc_before[1, "max"], 8)) / 1024^2

analysis_start <- Sys.time()
result <- find_connected_components(edges, compress = FALSE)
analysis_end <- Sys.time()

require(data.table)

gc_after <- gc(verbose = FALSE)
mem_after <- sum(gc_after[, "used"] * c(gc_after[1, "max"], 8)) / 1024^2

analysis_time <- as.numeric(analysis_end - analysis_start)
mem_used <- mem_after - mem_before

# Results
cat("✓ ANALYSIS COMPLETE!\n")
cat("✓ Processing time:", round(analysis_time, 3), "seconds\n")
cat("✓ Throughput:", round(nrow(edges) / analysis_time / 1000000, 2), "million edges/second\n")
cat("✓ Memory used:", round(mem_used, 1), "MB\n")
cat("✓ Memory efficiency:", round(mem_used * 1024 / nrow(edges), 4), "KB per edge\n")
cat("✓ Found", result$n_components, "connected components\n")

# Component size analysis
sorted_sizes <- sort(result$component_sizes, decreasing = TRUE)
cat("✓ Largest component:", max(sorted_sizes), "nodes\n")
cat("✓ Smallest component:", min(sorted_sizes), "nodes\n")
cat("✓ Average component size:", round(mean(sorted_sizes), 1), "nodes\n")
cat("✓ Top 10 component sizes:", paste(head(sorted_sizes, 10), collapse = ", "), "\n")

# Performance summary
total_time <- gen_time + analysis_time
cat("\n=== PERFORMANCE SUMMARY ===\n")
cat("Total runtime:", round(total_time, 2), "seconds\n")
cat("Graph generation:", round(100 * gen_time / total_time, 1), "% of time\n")
cat("Component analysis:", round(100 * analysis_time / total_time, 1), "% of time\n")
cat("Overall throughput:", round(nrow(edges) / total_time / 1000000, 2), "million edges/second\n")

x <- as.data.table(edges)
colnames(x) <- c("from", "to")

# Add component information for both source and target nodes
# result$components has one entry per node, indexed by node ID
x[, from_component := result$components[from]]
x[, to_component := result$components[to]]

# Mark edges as intra-component (within same component) or inter-component
x[, edge_type := ifelse(from_component == to_component, "intra", "inter")]

# Show a summary
cat("\n=== EDGE ANALYSIS ===\n")
cat("Total edges:", nrow(x), "\n")
cat("Intra-component edges:", sum(x$edge_type == "intra"), "\n")
cat("Inter-component edges:", sum(x$edge_type == "inter"), "\n")
cat("Percentage intra-component:", round(100 * sum(x$edge_type == "intra") / nrow(x), 2), "%\n")

# Show first few rows
cat("\nFirst 10 edges with component info:\n")
print(head(x, 10))

# Scale comparison
if (nrow(edges) >= 1000000) {
  cat("\n=== SCALE ACHIEVEMENT ===\n")
  cat("Successfully processed", round(nrow(edges) / 1000000, 1), "MILLION edges!\n")
  if (nrow(edges) >= 10000000) {
    cat("🎉 MASSIVE SCALE: Over 10 million edges processed!\n")
  }
  if (nrow(edges) >= 40000000) {
    cat("🚀 EXTREME SCALE: Over 40 million edges processed!\n")
  }
}

cat("\nGraphFast performance test completed successfully!\n")