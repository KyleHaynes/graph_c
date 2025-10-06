test_that("input validation works for all functions", {
  # Test find_connected_components
  expect_error(find_connected_components(matrix(1:3, ncol = 1)), "exactly 2 columns")
  expect_error(find_connected_components(matrix(c(0, 1), ncol = 2)), "positive integers")
  expect_error(find_connected_components("not a matrix"), "matrix or data.frame")
  
  # Test are_connected
  edges <- matrix(c(1, 2, 2, 3), ncol = 2, byrow = TRUE)
  expect_error(are_connected("not a matrix", matrix(c(1, 2), ncol = 2)), "matrix or data.frame")
  expect_error(are_connected(edges, matrix(1:3, ncol = 1)), "exactly 2 columns")
  
  # Test shortest_paths
  expect_error(shortest_paths("not a matrix", matrix(c(1, 2), ncol = 2)), "matrix or data.frame")
  expect_error(shortest_paths(edges, matrix(1:3, ncol = 1)), "exactly 2 columns")
  
  # Test graph_statistics
  expect_error(graph_statistics("not a matrix"), "matrix or data.frame")
  expect_error(graph_statistics(matrix(1:3, ncol = 1)), "exactly 2 columns")
})

test_that("data type conversion works", {
  # Test with data.frame input
  edges_df <- data.frame(from = c(1, 2, 3), to = c(2, 3, 4))
  
  result_components <- find_connected_components(edges_df)
  result_connected <- are_connected(edges_df, data.frame(from = c(1, 2), to = c(4, 5)))
  result_paths <- shortest_paths(edges_df, data.frame(from = c(1), to = c(4)))
  result_stats <- graph_statistics(edges_df)
  
  expect_type(result_components, "list")
  expect_type(result_connected, "logical")
  expect_type(result_paths, "integer")
  expect_type(result_stats, "list")
})

test_that("automatic n_nodes calculation works", {
  edges <- matrix(c(1, 2, 2, 5, 5, 10), ncol = 2, byrow = TRUE)
  
  # Without specifying n_nodes
  result1 <- find_connected_components(edges)
  result2 <- graph_statistics(edges)
  
  # With specifying n_nodes
  result3 <- find_connected_components(edges, n_nodes = 10)
  result4 <- graph_statistics(edges, n_nodes = 10)
  
  expect_type(result1, "list")
  expect_type(result2, "list")
  expect_type(result3, "list")
  expect_type(result4, "list")
  
  # Results should be consistent
  expect_equal(result1$n_components, result3$n_components)
})

test_that("compression works correctly", {
  edges <- matrix(c(1, 2, 2, 3, 5, 6, 6, 7), ncol = 2, byrow = TRUE)
  
  # With compression
  result_compressed <- find_connected_components(edges, compress = TRUE)
  
  # Without compression  
  result_uncompressed <- find_connected_components(edges, compress = FALSE)
  
  expect_equal(result_compressed$n_components, result_uncompressed$n_components)
  expect_equal(length(result_compressed$component_sizes), length(result_uncompressed$component_sizes))
})

test_that("edge cases are handled", {
  # Empty graph
  empty_edges <- matrix(integer(0), ncol = 2)
  result_empty <- find_connected_components(empty_edges)
  
  expect_equal(result_empty$n_components, 0)
  expect_equal(length(result_empty$components), 0)
  expect_equal(length(result_empty$component_sizes), 0)
  
  # Single node (self-loop)
  self_loop <- matrix(c(1, 1), ncol = 2)
  result_self <- find_connected_components(self_loop)
  
  expect_equal(result_self$n_components, 1)
  
  # Disconnected nodes in queries
  edges <- matrix(c(1, 2), ncol = 2)
  queries <- matrix(c(1, 3, 3, 4), ncol = 2, byrow = TRUE)
  
  result_disconnected <- are_connected(edges, queries)
  expect_equal(result_disconnected, c(FALSE, FALSE))
  
  result_paths <- shortest_paths(edges, queries)
  expect_equal(result_paths, c(-1, -1))
})

test_that("large integers are handled correctly", {
  # Test with large integer values
  large_edges <- matrix(c(.Machine$integer.max - 1, .Machine$integer.max - 2,
                          .Machine$integer.max - 2, .Machine$integer.max - 3), 
                        ncol = 2, byrow = TRUE)
  
  # This should not error
  expect_no_error(find_connected_components(large_edges))
})

test_that("mixed positive and negative handling", {
  # Negative numbers should be caught
  negative_edges <- matrix(c(-1, 2, 2, 3), ncol = 2, byrow = TRUE)
  
  expect_error(find_connected_components(negative_edges), "positive integers")
})

test_that("performance is reasonable for medium graphs", {
  # Create a medium-sized graph
  n_edges <- 50000
  edges <- matrix(sample(1:10000, 2 * n_edges, replace = TRUE), ncol = 2)
  
  # Should complete in reasonable time
  start_time <- Sys.time()
  result <- find_connected_components(edges)
  end_time <- Sys.time()
  
  expect_type(result, "list")
  expect_lt(as.numeric(end_time - start_time), 5)  # Should complete in < 5 seconds
})

test_that("all exported graph functions exist and work", {
  # Simple test data
  edges <- matrix(c(1, 2, 2, 3, 4, 5), ncol = 2, byrow = TRUE)
  queries <- matrix(c(1, 3, 1, 5), ncol = 2, byrow = TRUE)
  
  # Test all main functions don't error
  expect_no_error(find_connected_components(edges))
  expect_no_error(are_connected(edges, queries))
  expect_no_error(shortest_paths(edges, queries))
  expect_no_error(graph_statistics(edges))
  expect_no_error(group_edges(edges))
  expect_no_error(get_edge_components(edges))
  expect_no_error(find_connected_components_large(edges))
  expect_no_error(find_connected_components_safe(edges, verbose = FALSE))
})