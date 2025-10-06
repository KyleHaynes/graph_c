## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----eval=FALSE---------------------------------------------------------------
# # From GitHub
# devtools::install_github("KyleHaynes/graphfast")
# 
# # Build from source
# devtools::install()

## -----------------------------------------------------------------------------
library(graphfast)

## -----------------------------------------------------------------------------
# Customer data with potential duplicates
customers <- data.frame(
  customer_id = 1:6,
  name = c("John Smith", "Jane Doe", "J. Smith", "Bob Wilson", "Alice Brown", "John S."),
  phone1 = c("123-456-7890", "987-654-3210", "123-456-7890", "", "555-0123", ""),
  phone2 = c("", "987-654-3210", "555-1234", "123-456-7890", "", "123-456-7890"),
  email = c("john@email.com", "jane@email.com", "john2@email.com", "john@email.com", "alice@email.com", ""),
  stringsAsFactors = FALSE
)

print(customers)

## -----------------------------------------------------------------------------
# Find groups based on shared phone numbers and emails
group_ids <- group_id(customers, 
                      cols = c("phone1", "phone2", "email"),
                      incomparables = c("", "NA"))

customers$group_id <- group_ids
print(customers)

## -----------------------------------------------------------------------------
# Get detailed results with value mappings
result <- group_id(customers, 
                   cols = c("phone1", "phone2", "email"),
                   incomparables = c(""),
                   return_details = TRUE)

print(result)

## -----------------------------------------------------------------------------
# Use regex to match column names (default behavior)
group_ids_regex <- group_id(customers, 
                           cols = "phone",  # Matches "phone1", "phone2"
                           incomparables = c(""))

# Use exact column names
group_ids_exact <- group_id(customers, 
                           cols = c("phone1", "phone2"),
                           use_regex = FALSE,
                           incomparables = c(""))

print("Results are identical:", identical(group_ids_regex, group_ids_exact))

## -----------------------------------------------------------------------------
# Sample data
text_files <- c("error.log", "data.csv", "temp.txt", "config.json", 
                "test_results.log", "backup.tmp", "user_data.xml")

search_patterns <- c("log", "tmp", "test")

# Fast multi-pattern matching
matches <- text_files %fgrepl% search_patterns
print(matches)

# Show matching files
print(text_files[matches])

## -----------------------------------------------------------------------------
# Case-insensitive version
mixed_case <- c("ERROR.LOG", "Data.CSV", "TEMP.txt", "Test_File.doc")
lower_patterns <- c("error", "temp", "test")

# Case-sensitive (no matches)
case_sensitive <- mixed_case %fgrepl% lower_patterns
print(paste("Case-sensitive matches:", sum(case_sensitive)))

# Case-insensitive (matches found)
case_insensitive <- mixed_case %fgrepli% lower_patterns
print(paste("Case-insensitive matches:", sum(case_insensitive)))

## -----------------------------------------------------------------------------
# Create a simple graph
edges <- matrix(c(
  1, 2,
  2, 3,
  3, 4,
  1, 4,  # Creates a cycle
  5, 6,  # Separate component
  7, 8,
  8, 9
), ncol = 2, byrow = TRUE)

print(edges)

## -----------------------------------------------------------------------------
components <- find_connected_components(edges)
print(components)

## -----------------------------------------------------------------------------
# Check if these pairs are connected
query_pairs <- matrix(c(
  1, 3,  # Same component
  1, 5,  # Different components  
  7, 9   # Same component
), ncol = 2, byrow = TRUE)

connected <- are_connected(edges, query_pairs)
print(connected)

## -----------------------------------------------------------------------------
distances <- shortest_paths(edges, query_pairs)
print(distances)

## -----------------------------------------------------------------------------
# Generate test data
set.seed(42)
test_strings <- paste0(sample(c("error", "data", "temp", "config", "user"), 1000, replace = TRUE),
                      "_", sample(100:999, 1000, replace = TRUE), 
                      sample(c(".log", ".csv", ".tmp", ".json", ".xml"), 1000, replace = TRUE))

patterns <- c("error", "temp", "data")

# Base R approach
base_time <- system.time({
  base_result <- sapply(test_strings, function(s) any(sapply(patterns, function(p) grepl(p, s, fixed = TRUE))))
})

# Fast approach
fast_time <- system.time({
  fast_result <- test_strings %fgrepl% patterns
})

cat("Base R time:", base_time["elapsed"], "seconds\n")
cat("Fast time:", fast_time["elapsed"], "seconds\n")
cat("Speedup:", round(base_time["elapsed"] / fast_time["elapsed"], 1), "x\n")
cat("Results identical:", identical(as.logical(base_result), fast_result), "\n")

## -----------------------------------------------------------------------------
# Generate larger dataset for entity resolution
set.seed(123)
n_records <- 1000

large_customers <- data.frame(
  id = 1:n_records,
  phone1 = sample(c(paste0("555-", sample(1000:9999, 200)), rep("", 50)), n_records, replace = TRUE),
  phone2 = sample(c(paste0("555-", sample(1000:9999, 200)), rep("", 50)), n_records, replace = TRUE),
  email = sample(c(paste0("user", 1:300, "@email.com"), rep("", 50)), n_records, replace = TRUE),
  stringsAsFactors = FALSE
)

# Benchmark entity resolution
entity_time <- system.time({
  large_groups <- group_id(large_customers, 
                          cols = c("phone1", "phone2", "email"),
                          incomparables = c(""))
})

cat("Entity resolution time:", entity_time["elapsed"], "seconds\n")
cat("Records processed:", n_records, "\n")
cat("Groups found:", max(large_groups), "\n")
cat("Throughput:", round(n_records / entity_time["elapsed"]), "records/second\n")

## -----------------------------------------------------------------------------
# Generate a random graph with 10,000 nodes and 50,000 edges
set.seed(123)
n_nodes <- 10000
n_edges <- 50000

large_edges <- matrix(
  sample(1:n_nodes, 2 * n_edges, replace = TRUE), 
  ncol = 2
)

# Remove self-loops
large_edges <- large_edges[large_edges[,1] != large_edges[,2], ]

cat("Graph size:", nrow(large_edges), "edges,", n_nodes, "nodes\n")

## -----------------------------------------------------------------------------
# Benchmark connected components
system.time({
  large_result <- find_connected_components(large_edges)
})

cat("Found", large_result$n_components, "components\n")
cat("Largest component:", max(large_result$component_sizes), "nodes\n")

## -----------------------------------------------------------------------------
# Graph statistics without storing full adjacency matrix
stats <- graph_statistics(large_edges, n_nodes = n_nodes)
print(stats)

## -----------------------------------------------------------------------------
# Realistic customer deduplication scenario
customers_raw <- data.frame(
  customer_id = 1:10,
  name = c("John Smith", "Jane Doe", "J. Smith", "Bob Wilson", "Alice Brown", 
           "John S.", "Jane D.", "Robert W.", "John Smith", "B. Wilson"),
  phone1 = c("123-456-7890", "987-654-3210", "123-456-7890", "555-0123", "555-9876",
             "", "987-654-3210", "555-0123", "123-456-7890", ""),
  phone2 = c("", "987-654-3210", "555-1234", "123-456-7890", "",
             "123-456-7890", "", "999-888-7777", "", "555-0123"),
  email = c("john@email.com", "jane@email.com", "john2@email.com", "bob@email.com", "alice@email.com",
            "", "jane@email.com", "rob@email.com", "john@email.com", "bob@email.com"),
  stringsAsFactors = FALSE
)

# Perform deduplication
dedup_groups <- group_id(customers_raw, 
                        cols = c("phone1", "phone2", "email"),
                        incomparables = c("", "NA", "Unknown"),
                        min_group_size = 1)

customers_raw$duplicate_group <- dedup_groups

# Show results
print(customers_raw)

# Summary of duplicates
duplicate_summary <- table(customers_raw$duplicate_group)
cat("Duplicate groups found:", sum(duplicate_summary > 1), "\n")
cat("Total duplicates identified:", sum(duplicate_summary) - sum(duplicate_summary == 1), "\n")

## -----------------------------------------------------------------------------
# Simulate log file analysis
log_entries <- c(
  "2023-10-01 ERROR: Database connection failed",
  "2023-10-01 INFO: User login successful", 
  "2023-10-01 WARNING: High memory usage detected",
  "2023-10-01 ERROR: File not found",
  "2023-10-01 DEBUG: Processing request",
  "2023-10-01 ERROR: Authentication failed",
  "2023-10-01 INFO: Backup completed",
  "2023-10-01 WARNING: Disk space low"
)

# Find critical entries
critical_patterns <- c("ERROR", "CRITICAL", "FATAL")
warnings_patterns <- c("WARNING", "WARN")

critical_entries <- log_entries %fgrepli% critical_patterns
warning_entries <- log_entries %fgrepli% warnings_patterns

cat("Critical entries found:", sum(critical_entries), "\n")
cat("Warning entries found:", sum(warning_entries), "\n")

# Show critical entries
print("Critical log entries:")
print(log_entries[critical_entries])

## -----------------------------------------------------------------------------
# Simulate a social network with communities
generate_social_network <- function(n_users, connection_prob) {
  edges <- matrix(nrow = 0, ncol = 2)
  
  for (i in 1:(n_users-1)) {
    for (j in (i+1):n_users) {
      if (runif(1) < connection_prob) {
        edges <- rbind(edges, c(i, j))
      }
    }
  }
  
  return(edges)
}

# Generate a small social network
social_edges <- generate_social_network(100, 0.05)
cat("Social network with", nrow(social_edges), "friendships\n")

# Find communities (connected components)
communities <- find_connected_components(social_edges, n_nodes = 100)
cat("Found", communities$n_components, "communities\n")
cat("Community sizes:", paste(sort(communities$component_sizes, decreasing = TRUE), collapse = ", "), "\n")

## -----------------------------------------------------------------------------
# Simulate web page links
web_pages <- 500
link_prob <- 0.01

web_edges <- matrix(nrow = 0, ncol = 2)
for (i in 1:web_pages) {
  # Each page links to a few others
  n_links <- rpois(1, 3)
  if (n_links > 0) {
    targets <- sample(setdiff(1:web_pages, i), min(n_links, web_pages-1))
    for (target in targets) {
      web_edges <- rbind(web_edges, c(i, target))
    }
  }
}

cat("Web graph with", nrow(web_edges), "links between", web_pages, "pages\n")

# Analyze link structure  
web_stats <- graph_statistics(web_edges, n_nodes = web_pages)
cat("Web graph density:", round(web_stats$density, 4), "\n")
cat("Average out-degree:", round(web_stats$degree_stats$mean, 2), "\n")

# Find strongly connected components
web_components <- find_connected_components(web_edges, n_nodes = web_pages)
cat("Found", web_components$n_components, "connected regions\n")

## -----------------------------------------------------------------------------
# Generate many connectivity queries
n_queries <- 1000
query_nodes <- sample(1:100, 2 * n_queries, replace = TRUE)
batch_queries <- matrix(query_nodes, ncol = 2)

# Process all queries at once
system.time({
  batch_results <- are_connected(social_edges, batch_queries, n_nodes = 100)
})

cat("Processed", n_queries, "queries\n")
cat("Connected pairs:", sum(batch_results), "out of", n_queries, "\n")

## -----------------------------------------------------------------------------
# Monitor memory usage for large graphs
monitor_memory <- function(expr) {
  gc_before <- gc()
  result <- expr
  gc_after <- gc()
  
  memory_diff <- (gc_after["Vcells", "used"] - gc_before["Vcells", "used"]) * 8 / 1024^2
  cat("Memory used:", round(memory_diff, 2), "MB\n")
  
  return(result)
}

# Test memory usage
monitor_memory({
  test_result <- find_connected_components(large_edges)
})

