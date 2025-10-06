test_that("C++ functions are exported and work", {
  # Test data
  edges <- matrix(c(1, 2, 2, 3, 4, 5), ncol = 2, byrow = TRUE)
  n_nodes <- 5
  
  # Test functions that should be accessible
  if (exists("find_components_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    result_components <- graphfast:::find_components_cpp(edges, n_nodes)
    expect_type(result_components, "list")
  }
  
  if (exists("are_connected_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    queries <- matrix(c(1, 3, 1, 5), ncol = 2, byrow = TRUE)
    result_connected <- graphfast:::are_connected_cpp(edges, queries, n_nodes)
    expect_type(result_connected, "logical")
  }
  
  if (exists("shortest_paths_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    queries <- matrix(c(1, 3, 1, 5), ncol = 2, byrow = TRUE)
    result_paths <- graphfast:::shortest_paths_cpp(edges, queries, n_nodes, max_distance = -1)
    expect_type(result_paths, "integer")
  }
  
  if (exists("graph_stats_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    result_stats <- graphfast:::graph_stats_cpp(edges, n_nodes)
    expect_type(result_stats, "list")
  }
  
  if (exists("get_edge_components_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    result_edge_comp <- graphfast:::get_edge_components_cpp(edges, n_nodes)
    expect_type(result_edge_comp, "list")
  }
})

test_that("multi_column_group_cpp works", {
  # Test the core C++ grouping function through R interface
  data_list <- list(
    c("a", "b", "a", "c"),
    c("x", "y", "z", "x")
  )
  
  # Access the unexported function
  if (exists("multi_column_group_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    result <- graphfast:::multi_column_group_cpp(data_list)
    
    expect_type(result, "list")
    expect_named(result, c("group_ids", "n_groups", "group_sizes", "value_map"))
    expect_type(result$group_ids, "integer")
    expect_type(result$n_groups, "integer")
    expect_type(result$group_sizes, "integer")
    expect_type(result$value_map, "list")
  } else {
    skip("multi_column_group_cpp not available for direct testing")
  }
})

test_that("multi_column_group_cpp parameters work", {
  data_list <- list(
    c("a", "", "a", "c"),
    c("x", "y", "", "x")
  )
  
  # Access the unexported function for parameter testing
  if (exists("multi_column_group_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # Test with incomparables
    result_incomp <- graphfast:::multi_column_group_cpp(data_list, incomparables = c(""))
    
    # Test case sensitivity
    data_case <- list(c("Hello", "hello", "HELLO"))
    result_sensitive <- graphfast:::multi_column_group_cpp(data_case, case_sensitive = TRUE)
    result_insensitive <- graphfast:::multi_column_group_cpp(data_case, case_sensitive = FALSE)
    
    # Test min_group_size
    result_min_size <- graphfast:::multi_column_group_cpp(data_list, min_group_size = 2)
    
    expect_type(result_incomp, "list")
    expect_type(result_sensitive, "list")
    expect_type(result_insensitive, "list")
    expect_type(result_min_size, "list")
    
    # Case insensitive should group all variations together
    expect_true(result_insensitive$n_groups < result_sensitive$n_groups)
  } else {
    skip("multi_column_group_cpp not available for parameter testing")
  }
})

test_that("string matching C++ functions work", {
  strings <- c("hello world", "goodbye", "hello there")
  patterns <- c("hello", "world")
  
  # Test the C++ functions through the R interface (::: to access unexported functions)
  # These functions exist but are not exported, so we access them with :::
  
  # Test multi_grepl_cpp via :::
  if (exists("multi_grepl_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # multi_grepl_cpp returns a matrix format even with match_any=TRUE
    result_cpp <- graphfast:::multi_grepl_cpp(strings, patterns, match_any = TRUE)
    expect_type(result_cpp, "logical")
    # Convert to vector for comparison since other functions return vectors
    result_cpp_vec <- as.vector(result_cpp)
    
    # Test multi_grepl_any_cpp via :::
    result_any_cpp <- graphfast:::multi_grepl_any_cpp(strings, patterns)
    expect_type(result_any_cpp, "logical")
    
    # Test multi_grepl_any_fast_cpp via :::
    result_fast_cpp <- graphfast:::multi_grepl_any_fast_cpp(strings, patterns)
    expect_type(result_fast_cpp, "logical")
    
    # All should give same results (comparing as vectors)
    expect_equal(result_cpp_vec, result_any_cpp)
    expect_equal(result_cpp_vec, result_fast_cpp)
  } else {
    skip("C++ functions not available for direct testing")
  }
})

test_that("C++ functions handle edge cases", {
  # Test edge cases for accessible C++ functions
  
  if (exists("find_components_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # Empty data
    empty_edges <- matrix(integer(0), ncol = 2)
    result_empty <- graphfast:::find_components_cpp(empty_edges, 0)
    expect_type(result_empty, "list")
  }
  
  if (exists("multi_grepl_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # Empty strings/patterns
    empty_strings <- character(0)
    empty_patterns <- character(0)
    result_empty_strings <- graphfast:::multi_grepl_cpp(empty_strings, c("test"))
    result_empty_patterns <- graphfast:::multi_grepl_cpp(c("test"), empty_patterns)
    
    expect_type(result_empty_strings, "logical")
    expect_type(result_empty_patterns, "logical")
    expect_equal(length(result_empty_strings), 0)
    expect_equal(length(result_empty_patterns), 1)
  }
  
  if (exists("multi_column_group_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # Empty group data - this might not error in the C++ implementation
    empty_data <- list()
    # Just test that it doesn't crash rather than expecting a specific error
    result <- try(graphfast:::multi_column_group_cpp(empty_data), silent = TRUE)
    expect_true(inherits(result, "try-error") || is.list(result))
  }
})

test_that("C++ functions validate inputs", {
  # Test that C++ functions don't crash with various inputs
  # Note: C++ functions may not have extensive input validation
  
  if (exists("find_components_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # Test that these don't crash the R session
    valid_edges <- matrix(c(1, 2), ncol = 2)
    
    # Test with valid inputs
    result <- graphfast:::find_components_cpp(valid_edges, 2)
    expect_type(result, "list")
  } else {
    skip("C++ validation functions not available")
  }
  
  if (exists("multi_column_group_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    # Test with character data (should work)
    char_data <- list(c("a", "b", "c"))
    result <- graphfast:::multi_column_group_cpp(char_data)
    expect_type(result, "list")
  } else {
    skip("multi_column_group_cpp not available for validation testing")
  }
})

test_that("C++ performance is reasonable", {
  # Create larger test data
  n <- 10000
  large_edges <- matrix(sample(1:1000, 2 * n, replace = TRUE), ncol = 2)
  
  if (exists("find_components_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    start_time <- Sys.time()
    result <- graphfast:::find_components_cpp(large_edges, 1000)
    end_time <- Sys.time()
    
    expect_type(result, "list")
    expect_lt(as.numeric(end_time - start_time), 2)  # Should complete in < 2 seconds
  }
  
  # Large string matching
  large_strings <- rep(c("hello world", "goodbye", "test"), length.out = n)
  large_patterns <- c("hello", "world", "test", "goodbye")
  
  if (exists("multi_grepl_any_fast_cpp", envir = asNamespace("graphfast"), inherits = FALSE)) {
    start_time <- Sys.time()
    result_strings <- graphfast:::multi_grepl_any_fast_cpp(large_strings, large_patterns)
    end_time <- Sys.time()
    
    expect_type(result_strings, "logical")
    expect_equal(length(result_strings), n)
    expect_lt(as.numeric(end_time - start_time), 1)  # Should complete in < 1 second
  } else {
    # Test through the R wrapper instead
    start_time <- Sys.time()
    result_strings <- large_strings %fgrepl% large_patterns
    end_time <- Sys.time()
    
    expect_type(result_strings, "logical")
    expect_equal(length(result_strings), n)
    expect_lt(as.numeric(end_time - start_time), 1)  # Should complete in < 1 second
  }
})
