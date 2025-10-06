test_that("find_connected_components_large works", {
  # Test with large node IDs that would cause memory issues with naive approach
  edges <- matrix(c(1000000, 2000000, 
                    2000000, 3000000,
                    5000000, 6000000), 
                  ncol = 2, byrow = TRUE)
  
  result <- find_connected_components_large(edges)
  
  expect_type(result, "list")
  expect_named(result, c("components", "component_sizes", "n_components", "node_mapping"))
  
  expect_equal(result$n_components, 2)
  expect_type(result$components, "integer")
  expect_type(result$component_sizes, "integer")
  expect_s3_class(result$node_mapping, "data.frame")
})

test_that("find_connected_components_safe works", {
  # Test the memory-safe version
  edges <- matrix(c(1, 2, 2, 3, 5, 6), ncol = 2, byrow = TRUE)
  
  # Test with verbose = FALSE
  result <- find_connected_components_safe(edges, verbose = FALSE)
  
  expect_type(result, "list")
  expect_named(result, c("components", "component_sizes", "n_components", "node_mapping"))
  expect_equal(result$n_components, 2)
})

test_that("get_edge_components works", {
  edges <- matrix(c(1, 2, 2, 3, 4, 5), ncol = 2, byrow = TRUE)
  
  # Test different return types
  result_list <- get_edge_components(edges, return_type = "list")
  result_df <- get_edge_components(edges, return_type = "data.frame")
  result_vector <- get_edge_components(edges, return_type = "vector")
  
  expect_type(result_list, "list")
  expect_s3_class(result_df, "data.frame")
  expect_type(result_vector, "integer")
  
  # List should have from_components and to_components
  expect_named(result_list, c("from_components", "to_components"))
  
  # Data frame should have from_component and to_component columns
  expect_true(all(c("from_component", "to_component") %in% names(result_df)))
  
  # Vector should alternate from, to, from, to...
  expect_equal(length(result_vector), 2 * nrow(edges))
})

test_that("group_edges works", {
  edges <- matrix(c(1, 2, 2, 3, 4, 5, 5, 6), ncol = 2, byrow = TRUE)
  
  result <- group_edges(edges)
  
  expect_type(result, "list")
  expect_named(result, c("edge_groups", "group_sizes", "n_groups"))
  
  expect_type(result$edge_groups, "integer")
  expect_equal(length(result$edge_groups), nrow(edges))
  expect_type(result$group_sizes, "integer")
  expect_type(result$n_groups, "integer")
})

test_that("add_component_column works", {
  skip_if_not_installed("data.table")
  
  dt <- data.table::data.table(
    from = c(1, 2, 4, 5),
    to = c(2, 3, 5, 6),
    weight = c(1.0, 2.0, 3.0, 4.0)
  )
  
  result <- add_component_column(dt)
  
  expect_true("component" %in% names(result))
  expect_equal(nrow(result), nrow(dt))
  expect_type(result$component, "integer")
})

test_that("edge_components works", {
  skip_if_not_installed("data.table")
  
  dt <- data.table::data.table(
    source = c(1, 2, 4, 5),
    target = c(2, 3, 5, 6)
  )
  
  result <- edge_components(dt, from_col = "source", to_col = "target")
  
  expect_type(result, "integer")
  expect_equal(length(result), nrow(dt))
})

test_that("large graph functions handle edge cases", {
  # Empty edges
  empty_edges <- matrix(integer(0), ncol = 2)
  
  result_large <- find_connected_components_large(empty_edges)
  result_safe <- find_connected_components_safe(empty_edges, verbose = FALSE)
  
  expect_equal(result_large$n_components, 0)
  expect_equal(result_safe$n_components, 0)
  
  # Single edge
  single_edge <- matrix(c(1, 2), ncol = 2)
  
  result_large_single <- find_connected_components_large(single_edge)
  result_safe_single <- find_connected_components_safe(single_edge, verbose = FALSE)
  
  expect_equal(result_large_single$n_components, 1)
  expect_equal(result_safe_single$n_components, 1)
})

test_that("compression option works", {
  edges <- matrix(c(1, 2, 2, 3, 5, 6), ncol = 2, byrow = TRUE)
  
  # With compression (default)
  result_compressed <- find_connected_components_large(edges, compress = TRUE)
  
  # Without compression
  result_uncompressed <- find_connected_components_large(edges, compress = FALSE)
  
  expect_type(result_compressed, "list")
  expect_type(result_uncompressed, "list")
  
  # Both should have same number of components
  expect_equal(result_compressed$n_components, result_uncompressed$n_components)
})

test_that("node mapping is correct", {
  # Use node IDs that are not consecutive
  edges <- matrix(c(100, 200, 200, 300, 500, 600), ncol = 2, byrow = TRUE)
  
  result <- find_connected_components_large(edges)
  
  expect_s3_class(result$node_mapping, "data.frame")
  expect_true(all(c("original_id", "mapped_id") %in% names(result$node_mapping)))
  
  # Should have mapping for all unique nodes
  unique_nodes <- unique(c(edges[,1], edges[,2]))
  expect_equal(nrow(result$node_mapping), length(unique_nodes))
  
  # Original IDs should match our input
  expect_true(all(unique_nodes %in% result$node_mapping$original_id))
})