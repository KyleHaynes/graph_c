test_that("package handles large datasets efficiently", {
  skip_on_cran()  # Skip these on CRAN as they take time
  
  # Large graph test
  n_nodes <- 100000
  n_edges <- 500000
  large_edges <- matrix(sample(1:n_nodes, 2 * n_edges, replace = TRUE), ncol = 2)
  
  start_time <- Sys.time()
  result <- find_connected_components(large_edges)
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time)
  
  expect_type(result, "list")
  expect_lt(elapsed, 10)  # Should complete in < 10 seconds
  
  # Memory usage should be reasonable
  expect_lt(object.size(result), object.size(large_edges) * 2)
})

test_that("string matching scales well", {
  skip_on_cran()
  
  # Large string matching test
  n_strings <- 1000000
  patterns <- c("error", "warning", "info", "debug", "trace", "fatal")
  
  # Create realistic log-like strings
  string_templates <- c(
    "2023-01-01 10:00:00 ERROR Something went wrong",
    "2023-01-01 10:00:01 WARNING This is a warning",
    "2023-01-01 10:00:02 INFO Application started",
    "2023-01-01 10:00:03 DEBUG Debugging information",
    "2023-01-01 10:00:04 TRACE Detailed trace",
    "2023-01-01 10:00:05 FATAL Critical error"
  )
  
  large_strings <- sample(string_templates, n_strings, replace = TRUE)
  
  start_time <- Sys.time()
  result <- large_strings %fgrepl% patterns
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time)
  
  expect_type(result, "logical")
  expect_equal(length(result), n_strings)
  expect_lt(elapsed, 5)  # Should complete in < 5 seconds
  
  # Should find matches in all strings (since all contain one of the patterns)
  expect_equal(sum(result), n_strings)
})

test_that("group_id scales with complex data", {
  skip_on_cran()
  
  # Generate realistic customer-like data
  n_customers <- 100000
  
  # Create pools of realistic values
  phone_area_codes <- c("212", "646", "917", "718", "347", "929")
  phone_numbers <- paste0(sample(phone_area_codes, n_customers, replace = TRUE), 
                         sprintf("%07d", sample(1:9999999, n_customers, replace = TRUE)))
  
  email_domains <- c("gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "company.com")
  email_users <- paste0("user", sample(1:50000, n_customers, replace = TRUE))
  emails <- paste0(email_users, "@", sample(email_domains, n_customers, replace = TRUE))
  
  # Create overlapping data (some customers share phones/emails)
  overlap_rate <- 0.1  # 10% overlap
  n_overlap <- as.integer(n_customers * overlap_rate)
  
  # Introduce some shared values
  phone_numbers[sample(n_customers, n_overlap)] <- sample(phone_numbers[1:1000], n_overlap, replace = TRUE)
  emails[sample(n_customers, n_overlap)] <- sample(emails[1:1000], n_overlap, replace = TRUE)
  
  # Add some empty/null values
  phone_numbers[sample(n_customers, n_customers * 0.05)] <- ""
  emails[sample(n_customers, n_customers * 0.03)] <- ""
  
  customer_data <- data.frame(
    id = 1:n_customers,
    phone1 = phone_numbers,
    phone2 = sample(c(phone_numbers, rep("", n_customers * 0.7)), n_customers),
    email1 = emails,
    email2 = sample(c(emails, rep("", n_customers * 0.8)), n_customers),
    stringsAsFactors = FALSE
  )
  
  start_time <- Sys.time()
  result <- group_id(customer_data, 
                     cols = c("phone1", "phone2", "email1", "email2"),
                     incomparables = c(""),
                     min_group_size = 2)
  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time)
  
  expect_type(result, "integer")
  expect_equal(length(result), n_customers)
  expect_lt(elapsed, 30)  # Should complete in < 30 seconds
  
  # Should find some groups due to overlapping data
  expect_true(max(result) > 1)
  expect_true(any(result == 0))  # Some singletons due to min_group_size = 2
})

test_that("memory usage is reasonable under stress", {
  skip_on_cran()
  
  if (requireNamespace("pryr", quietly = TRUE)) {
    # Monitor memory usage during large operations
    initial_memory <- pryr::mem_used()
    
    # Large graph operations
    n_edges <- 200000
    edges <- matrix(sample(1:50000, 2 * n_edges, replace = TRUE), ncol = 2)
    
    mem_before_graph <- pryr::mem_used()
    result_graph <- find_connected_components(edges)
    mem_after_graph <- pryr::mem_used()
    
    graph_memory_used <- as.numeric(mem_after_graph - mem_before_graph) / 1024^2  # MB
    
    # Memory usage should be reasonable (less than 10x the input size)
    input_size_mb <- as.numeric(object.size(edges)) / 1024^2
    expect_lt(graph_memory_used, input_size_mb * 10)
    
    # Clean up
    rm(result_graph, edges)
    gc()
    
    # Large string operations
    n_strings <- 500000
    test_strings <- rep(c("hello world", "goodbye", "test file", "log entry"), 
                        length.out = n_strings)
    patterns <- c("hello", "world", "test", "log", "file")
    
    mem_before_string <- pryr::mem_used()
    result_string <- multi_grepl(test_strings, patterns)
    mem_after_string <- pryr::mem_used()
    
    string_memory_used <- as.numeric(mem_after_string - mem_before_string) / 1024^2  # MB
    
    # String operations should be memory efficient
    expect_lt(string_memory_used, 100)  # Less than 100MB for this operation
    
    expect_type(result_string, "logical")
    expect_equal(length(result_string), n_strings)
  } else {
    skip("pryr package not available for memory testing")
  }
})

test_that("concurrent-like access patterns work", {
  # Simulate patterns that might occur in multi-threaded environments
  # (R is single-threaded, but this tests robustness)
  
  edges <- matrix(c(1, 2, 2, 3, 3, 4, 4, 5), ncol = 2, byrow = TRUE)
  
  # Multiple rapid calls
  results <- list()
  for (i in 1:100) {
    results[[i]] <- find_connected_components(edges)
  }
  
  # All results should be identical
  for (i in 2:100) {
    expect_equal(results[[1]], results[[i]])
  }
})

test_that("edge cases don't cause crashes", {
  # Test various edge cases that might cause crashes
  
  # Very large node IDs
  if (.Machine$integer.max > 2^30) {
    large_id_edges <- matrix(c(.Machine$integer.max - 1, .Machine$integer.max - 2), ncol = 2)
    expect_no_error(find_connected_components(large_id_edges))
  }
  
  # Many duplicate edges
  duplicate_edges <- matrix(rep(c(1, 2), 10000), ncol = 2, byrow = TRUE)
  expect_no_error(find_connected_components(duplicate_edges))
  
  # Self-loops
  self_loops <- matrix(c(1, 1, 2, 2, 3, 3), ncol = 2, byrow = TRUE)
  expect_no_error(find_connected_components(self_loops))
  
  # Mixed data types (should be converted)
  mixed_edges <- data.frame(from = as.character(1:3), to = as.character(2:4))
  expect_no_error(find_connected_components(mixed_edges))
  
  # Very long strings
  very_long_string <- paste(rep("a", 10000), collapse = "")
  long_strings <- c(very_long_string, "short", very_long_string)
  expect_no_error(multi_grepl(long_strings, c("a", "short")))
  
  # Many patterns
  many_patterns <- paste0("pattern", 1:1000)
  test_string <- c("this contains pattern500", "this contains pattern999")
  expect_no_error(multi_grepl(test_string, many_patterns))
})