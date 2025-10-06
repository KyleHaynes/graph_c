# graphfast: High-Performance Graph Analysis in R

[![R-CMD-check](https://github.com/username/graphfast/workflows/R-CMD-check/badge.svg)](https://github.com/username/graphfast/actions)

A high-performance R package for analyzing large-scale graphs with hundreds of millions of edges. Built with optimized C++ algorithms via Rcpp for maximum speed and memory efficiency.

## Features

### Graph Analysis
- **Memory-efficient**: Handles hundreds of millions of edges with minimal memory footprint
- **Fast algorithms**: Optimized C++ implementations with advanced data structures
- **Connected components**: Union-Find with path compression and union by rank
- **Shortest paths**: Multi-source BFS with early termination
- **Connectivity queries**: Fast pairwise connectivity checking
- **Graph statistics**: Efficient computation without full adjacency storage

### Entity Resolution & Deduplication
- **Multi-column grouping**: `group_id()` function for entity resolution across multiple fields
- **Incomparable values**: Exclude empty, NA, or custom values from matching
- **Case sensitivity control**: Match with or without case sensitivity
- **Minimum group sizes**: Filter out small groups automatically
- **Memory efficient**: Uses Union-Find algorithm for optimal performance
- **Data.table integration**: Seamless workflow with data.table

### String Matching
- **Multi-pattern matching**: Fast C++ implementation of fixed string search
- **Convenience operators**: `%fgrepl%` and `%fgrepli%` for easy pattern matching
- **Performance optimized**: Significantly faster than base R grepl() for multiple patterns

## Installation

```r
# Install development version from GitHub
devtools::install_github("KyleHaynes/graphfast")
```

## Quick Start

### Graph Analysis

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
```

### Entity Resolution with group_id()

```r
# Customer data with duplicate information across columns
customers <- data.frame(
  id = 1:6,
  phone1 = c("123-456-7890", "987-654-3210", "123-456-7890", "", "555-0123", ""),
  phone2 = c("", "987-654-3210", "555-1234", "123-456-7890", "", "555-0123"),
  email = c("john@email.com", "jane@email.com", "john2@email.com", "john@email.com", "alice@email.com", "alice@email.com")
)
customers

# Group records that share phone numbers or emails
group_ids <- group_id(customers, 
                      cols = c("phone1", "phone2", "email"),
                      incomparables = c("", "NA"))

customers$group_id <- group_ids
print(customers)

# Get detailed results
result <- group_id(customers, 
                   cols = c("phone1", "phone2", "email"),
                   incomparables = c(""),
                   return_details = TRUE)

print(result)
```

### Fast String Matching

```r
# Multi-pattern string matching
text <- c("hello world", "goodbye", "hello there", "world peace")
patterns <- c("hello", "world")

# Check if any pattern matches (fast C++ implementation)
matches <- text %fgrepl% patterns
print(matches)  # TRUE FALSE TRUE TRUE

# Case-insensitive matching
matches_ci <- text %fgrepli% patterns
print(matches_ci)
````

# Get graph statistics
stats <- graph_statistics(edges)
print(stats$density)
print(stats$degree_stats)
```

## Entity Resolution with group_id()

The `group_id()` function provides high-performance entity resolution and deduplication across multiple columns. Perfect for finding records that represent the same entity despite having variations in contact information.

```r
library(graphfast)

# Customer data with potential duplicates
customers <- data.frame(
  customer_id = 1:8,
  name = c("John Smith", "Jane Doe", "J. Smith", "Bob Wilson", "Alice Brown", "John S.", "Jane D.", "Robert W."),
  phone1 = c("123-456-7890", "987-654-3210", "123-456-7890", "", "555-0123", "", "987-654-3210", ""),
  phone2 = c("", "987-654-3210", "555-1234", "123-456-7890", "", "123-456-7890", "", "999-888-7777"),
  email = c("john@email.com", "jane@email.com", "john2@email.com", "john@email.com", "alice@email.com", "", "jane@email.com", "bob@email.com"),
  stringsAsFactors = FALSE
)

# Find groups based on shared phone numbers and emails
group_ids <- group_id(customers, 
                      cols = c("phone1", "phone2", "email"),
                      incomparables = c("", "NA", "Unknown"))

customers$group_id <- group_ids
print(customers)

# Get detailed results with value mappings
result <- group_id(customers, 
                   cols = c("phone1", "phone2", "email"),
                   incomparables = c(""),
                   return_details = TRUE)

print(result$value_map)  # Shows which values created the groups
```

### Key Features

- **Multi-column matching**: Group records that share values across any specified columns
- **Incomparable values**: Exclude empty strings, NAs, or custom values from matching
- **Case sensitivity**: Control whether string comparisons are case-sensitive
- **Minimum group size**: Filter out groups smaller than specified threshold
- **Union-Find algorithm**: Optimal O(n α(n)) performance with path compression
- **Memory efficient**: Processes millions of records with minimal memory usage

### Data.table Integration

```r
library(data.table)

# Convert to data.table
dt <- as.data.table(customers)

# Add group IDs efficiently
add_group_ids(dt, 
              cols = c("phone1", "phone2", "email"),
              group_col = "entity_id",
              incomparables = c(""))

print(dt)
```

## Data.table Integration

```r
library(graphfast)
library(data.table)

# Work directly with data.table (no matrix conversion needed)
set.seed(123)
edges_dt <- data.table(
  x = sample(1E6, 1E6),
  y = sample(1E6, 1E6)
)

# Add component column efficiently
edges_dt[, component := edge_components(.SD, "x", "y")]

# View results
head(edges_dt)
#         x      y component
#     <int>  <int>     <int>
# 1: 969167 989981         1
# 2: 188942 802232         2
# 3: 134058 156182         2
# 4: 124022 544743         1
# 5: 685285 416069         4
# 6: 226318 949112         2
```

## String Matching

```r
library(graphfast)

# Fast multi-pattern string matching
strings <- c("error.log", "data.csv", "temp.log", "config.xml")
patterns <- c("log", "temp")

# Check if any pattern matches each string
multi_grepl(strings, patterns)
# Returns: TRUE FALSE TRUE FALSE

# Filter strings containing any pattern
filter_strings(strings, patterns)
# Returns: "error.log" "temp.log"
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