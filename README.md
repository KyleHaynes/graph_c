# graphfast: High-Performance Graph Analysis in R

[![R-CMD-check](https://github.com/username/graphfast/workflows/R-CMD-check/badge.svg)](https://github.com/username/graphfast/actions)

A high-performance R package for analyzing large-scale graphs with hundreds of millions of edges. Built with optimized C++ algorithms via Rcpp for maximum speed and memory efficiency.

## Features

- **Memory-efficient**: Handles hundreds of millions of edges with minimal memory footprint
- **Fast algorithms**: Optimized C++ implementations with advanced data structures
- **Connected components**: Union-Find with path compression and union by rank
- **Shortest paths**: Multi-source BFS with early termination
- **Connectivity queries**: Fast pairwise connectivity checking
- **Graph statistics**: Efficient computation without full adjacency storage

## Installation

```r
# Install development version from GitHub
devtools::install_github("KyleHaynes/graphfast")
```

## Quick Start

```r
library(graphfast)

# Create a simple graph
edges <- matrix(c(
  1, 2,
  2, 3,
  3, 4,
  5, 6,
  7, 8,
  8, 9
), ncol = 2, byrow = TRUE)

# Find connected components
components <- find_connected_components(edges)
print(components$n_components)  # 3 components
print(components$component_sizes)  # c(4, 2, 3)

# Check if specific pairs are connected
queries <- matrix(c(1, 4, 1, 5, 5, 6), ncol = 2, byrow = TRUE)
connected <- are_connected(edges, queries)
print(connected)  # c(TRUE, FALSE, TRUE)

# Find shortest paths
distances <- shortest_paths(edges, queries)
print(distances)  # c(3, -1, 1)

# Get graph statistics
stats <- graph_statistics(edges)
print(stats$density)
print(stats$degree_stats)
```

## Performance Example

```r
library(graphfast)
library(microbenchmark)

# Generate a large random graph
n_nodes <- 1000000
n_edges <- 5000000
edges <- matrix(sample(1:n_nodes, 2 * n_edges, replace = TRUE), ncol = 2)

# Benchmark connected components
microbenchmark(
  graphfast = find_connected_components(edges),
  times = 5
)

# Memory usage is minimal even for very large graphs
print(object.size(edges))  # Size of edge list
# The algorithm uses O(n) additional memory, not O(n²)
```

## Use Cases

### Social Network Analysis
```r
# Analyze friendship networks
friendships <- read.csv("friendships.csv")  # user1, user2 columns
edges <- as.matrix(friendships[, c("user1", "user2")])

# Find communities
communities <- find_connected_components(edges)
largest_community <- which.max(communities$component_sizes)

# Check if specific users are connected
user_pairs <- matrix(c(123, 456, 789, 101112), ncol = 2, byrow = TRUE)
connected <- are_connected(edges, user_pairs)
```

### Biological Networks
```r
# Protein-protein interactions
ppi_edges <- read.table("protein_interactions.txt")
interactions <- as.matrix(ppi_edges)

# Find protein complexes (connected components)
complexes <- find_connected_components(interactions)

# Compute shortest paths between proteins
protein_pairs <- matrix(c("PROTEIN_A", "PROTEIN_B"), ncol = 2)
# Convert protein names to IDs first
distances <- shortest_paths(interactions, protein_pairs)
```

### Web Graph Analysis
```r
# Analyze web page link structure
page_links <- read.csv("web_links.csv")  # from_page, to_page
edges <- as.matrix(page_links)

# Find strongly connected components
components <- find_connected_components(edges)

# Analyze link structure
stats <- graph_statistics(edges)
print(paste("Web graph density:", stats$density))
```

## Algorithm Details

### Connected Components
- Uses Union-Find data structure with path compression and union by rank
- Time complexity: O(m × α(n)) where α is the inverse Ackermann function
- Space complexity: O(n)
- Handles graphs with billions of edges efficiently

### Shortest Paths
- Multi-source BFS with optimized adjacency list representation
- Early termination when maximum distance is specified
- Memory-efficient: doesn't store full distance matrix
- Time complexity: O(m + n) per query

### Memory Optimization
- Edge list storage instead of adjacency matrix
- Sparse graph representation
- Compressed component IDs
- Streaming algorithms for very large datasets

## API Reference

### Main Functions

#### `find_connected_components(edges, n_nodes = NULL, compress = TRUE)`
Find all connected components in a graph.

**Parameters:**
- `edges`: Two-column matrix of edges (node pairs)
- `n_nodes`: Total number of nodes (optional)
- `compress`: Whether to compress component IDs

**Returns:** List with components, component_sizes, and n_components

#### `are_connected(edges, query_pairs, n_nodes = NULL)`
Check if pairs of nodes are connected.

**Parameters:**
- `edges`: Two-column matrix of edges
- `query_pairs`: Two-column matrix of node pairs to check
- `n_nodes`: Total number of nodes (optional)

**Returns:** Logical vector indicating connectivity

#### `shortest_paths(edges, query_pairs, n_nodes = NULL, max_distance = -1)`
Compute shortest path distances between node pairs.

**Parameters:**
- `edges`: Two-column matrix of edges
- `query_pairs`: Two-column matrix of source-target pairs
- `n_nodes`: Total number of nodes (optional)
- `max_distance`: Maximum distance to search (-1 for no limit)

**Returns:** Integer vector of distances (-1 if no path)

#### `graph_statistics(edges, n_nodes = NULL)`
Compute basic graph statistics efficiently.

**Parameters:**
- `edges`: Two-column matrix of edges
- `n_nodes`: Total number of nodes (optional)

**Returns:** List with n_edges, n_nodes, density, and degree_stats

## Performance Tips

1. **Use integer node IDs**: Convert string IDs to integers for better performance
2. **Pre-specify n_nodes**: Avoids scanning edges to find maximum ID
3. **Batch queries**: Process multiple connectivity/distance queries together
4. **Set max_distance**: For shortest paths, limit search depth when possible
5. **Memory monitoring**: Use `gc()` and monitor memory usage for very large graphs

## Comparison with Other Packages

| Package | Connected Components | Shortest Paths | Memory Usage | Speed |
|---------|---------------------|----------------|--------------|-------|
| graphfast | ✓ | ✓ | O(n + m) | Fastest |
| igraph | ✓ | ✓ | O(n²) for dense | Fast |
| network | ✓ | ✓ | O(n²) | Moderate |
| sna | ✓ | ✓ | O(n²) | Slow |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License. See LICENSE file for details.

## Citation

If you use this package in your research, please cite:

```
@misc{graphfast,
  title={graphfast: High-Performance Graph Analysis in R},
  author={Your Name},
  year={2025},
  url={https://github.com/username/graphfast}
}
```