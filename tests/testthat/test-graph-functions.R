test_that("find_connected_components works correctly", {
  # Simple graph: 1-2-3, 5-6, 8-9-10 (3 components)
  edges <- matrix(c(1,2, 2,3, 5,6, 8,9, 9,10), ncol=2, byrow=TRUE)
  result <- find_connected_components(edges)
  
  # Debug: check what we actually get
  # The graph has nodes: 1,2,3,5,6,8,9,10 = 8 unique nodes
  # Components: {1,2,3}, {5,6}, {8,9,10} = 3 components
  
  expect_equal(result$n_components, 3)
  expect_equal(length(result$components), 8)  # 8 unique nodes, not 10
  expect_equal(length(result$component_sizes), 3)
  expect_equal(sum(result$component_sizes), 8)  # Total nodes = 8
})

test_that("are_connected works correctly", {
  edges <- matrix(c(1,2, 2,3, 5,6), ncol=2, byrow=TRUE)
  queries <- matrix(c(1,3, 1,5, 5,6), ncol=2, byrow=TRUE)
  result <- are_connected(edges, queries)
  
  expect_equal(result, c(TRUE, FALSE, TRUE))
})

test_that("shortest_paths works correctly", {
  edges <- matrix(c(1,2, 2,3, 3,4), ncol=2, byrow=TRUE)
  queries <- matrix(c(1,4, 1,5), ncol=2, byrow=TRUE)
  result <- shortest_paths(edges, queries)
  
  expect_equal(result, c(3, -1))
})

test_that("graph_statistics works correctly", {
  edges <- matrix(c(1,2, 2,3, 3,1), ncol=2, byrow=TRUE)
  result <- graph_statistics(edges, n_nodes = 3)
  
  expect_equal(result$n_edges, 3)
  expect_equal(result$n_nodes, 3)
  expect_equal(result$degree_stats$mean, 2)
})

test_that("handles large graphs efficiently", {
  # Test with a larger graph
  n <- 10000
  edges <- cbind(1:(n-1), 2:n)  # Linear chain
  
  # This should complete quickly
  start_time <- Sys.time()
  result <- find_connected_components(edges)
  end_time <- Sys.time()
  
  expect_equal(result$n_components, 1)
  expect_lt(as.numeric(end_time - start_time), 1)  # Should complete in < 1 second
})

test_that("input validation works", {
  expect_error(find_connected_components(matrix(1:3, ncol=1)), "exactly 2 columns")
  expect_error(find_connected_components(matrix(c(0,1), ncol=2)), "positive integers")
  expect_error(are_connected("not a matrix", matrix(c(1,2), ncol=2)), "matrix or data.frame")
})