test_that("multi_grepl basic functionality works", {
  strings <- c("hello world", "goodbye", "hello there", "world peace")
  patterns <- c("hello", "world")
  
  # Test match_any = TRUE (default)
  result_any <- multi_grepl(strings, patterns)
  expected_any <- c(TRUE, FALSE, TRUE, TRUE)
  
  expect_equal(result_any, expected_any)
  expect_type(result_any, "logical")
  expect_equal(length(result_any), length(strings))
})

test_that("multi_grepl detailed results work", {
  strings <- c("hello world", "goodbye", "hello there", "world peace")
  patterns <- c("hello", "world")
  
  # Test match_any = FALSE, return_matrix = FALSE (data.frame)
  result_df <- multi_grepl(strings, patterns, match_any = FALSE, return_matrix = FALSE)
  
  expect_s3_class(result_df, "data.frame")
  expect_equal(nrow(result_df), length(strings))
  expect_equal(ncol(result_df), length(patterns))
  expect_equal(names(result_df), patterns)
  
  # Test match_any = FALSE, return_matrix = TRUE
  result_matrix <- multi_grepl(strings, patterns, match_any = FALSE, return_matrix = TRUE)
  
  expect_type(result_matrix, "logical")
  expect_true(is.matrix(result_matrix))
  expect_equal(nrow(result_matrix), length(strings))
  expect_equal(ncol(result_matrix), length(patterns))
  expect_equal(colnames(result_matrix), patterns)
})

test_that("multi_grepl case sensitivity works", {
  strings <- c("Hello World", "hello world", "HELLO WORLD")
  patterns <- c("hello", "HELLO")
  
  # Case sensitive (default)
  result_sensitive <- multi_grepl(strings, patterns, ignore_case = FALSE)
  
  # Case insensitive
  result_insensitive <- multi_grepl(strings, patterns, ignore_case = TRUE)
  
  expect_type(result_sensitive, "logical")
  expect_type(result_insensitive, "logical")
  
  # All should match in case insensitive mode
  expect_equal(result_insensitive, c(TRUE, TRUE, TRUE))
})

test_that("multi_grepl empty patterns work", {
  strings <- c("hello", "world")
  patterns <- character(0)
  
  # match_any = TRUE with empty patterns
  result_any <- multi_grepl(strings, patterns, match_any = TRUE)
  expect_equal(result_any, c(FALSE, FALSE))
  
  # match_any = FALSE with empty patterns
  result_matrix <- multi_grepl(strings, patterns, match_any = FALSE)
  expect_true(is.matrix(result_matrix))
  expect_equal(nrow(result_matrix), length(strings))
  expect_equal(ncol(result_matrix), 0)
})

test_that("multi_grepl input validation works", {
  # Non-character strings
  expect_error(multi_grepl(1:3, c("hello")), "strings must be a character vector")
  
  # Non-character patterns
  expect_error(multi_grepl(c("hello"), 1:3), "patterns must be a character vector")
})

test_that("%fgrepl% operator works", {
  strings <- c("hello world", "goodbye", "test file", "log entry")
  patterns <- c("hello", "log")
  
  result <- strings %fgrepl% patterns
  expected <- c(TRUE, FALSE, FALSE, TRUE)
  
  expect_equal(result, expected)
  expect_type(result, "logical")
})

test_that("%fgrepli% operator works", {
  strings <- c("Hello World", "GOODBYE", "Test File")
  patterns <- c("hello", "test")
  
  result <- strings %fgrepli% patterns
  expected <- c(TRUE, FALSE, TRUE)
  
  expect_equal(result, expected)
  expect_type(result, "logical")
})

test_that("multi_grepl C++ functions work directly", {
  skip("C++ functions not exported - testing through R wrappers instead")
  
  # This test is skipped because the C++ functions are not exported
  # They are tested indirectly through the R wrapper functions
})

test_that("multi_grepl performance is reasonable", {
  # Test with larger data
  n <- 10000
  strings <- rep(c("hello world", "goodbye cruel world", "test file"), length.out = n)
  patterns <- c("hello", "world", "test")
  
  # Should complete in reasonable time
  start_time <- Sys.time()
  result <- multi_grepl(strings, patterns)
  end_time <- Sys.time()
  
  expect_type(result, "logical")
  expect_equal(length(result), n)
  expect_lt(as.numeric(end_time - start_time), 1)  # Should complete in < 1 second
})

test_that("multi_grepl special characters work", {
  strings <- c("hello.world", "test@example.com", "path/to/file", "key=value")
  patterns <- c(".", "@", "/", "=")
  
  result <- multi_grepl(strings, patterns)
  expected <- c(TRUE, TRUE, TRUE, TRUE)
  
  expect_equal(result, expected)
})

test_that("filter_strings works", {
  strings <- c("error.log", "data.csv", "temp.log", "config.xml")
  patterns <- c("log", "temp")
  
  # Basic filtering
  result <- filter_strings(strings, patterns)
  expected <- c("error.log", "temp.log")
  
  expect_equal(result, expected)
  expect_type(result, "character")
  
  # Inverted filtering
  result_invert <- filter_strings(strings, patterns, invert = TRUE)
  expected_invert <- c("data.csv", "config.xml")
  
  expect_equal(result_invert, expected_invert)
})

test_that("filter_strings case sensitivity works", {
  strings <- c("Error.log", "DATA.CSV", "Temp.log")
  patterns <- c("error", "temp")
  
  # Case sensitive
  result_sensitive <- filter_strings(strings, patterns, ignore_case = FALSE)
  expect_equal(length(result_sensitive), 0)
  
  # Case insensitive
  result_insensitive <- filter_strings(strings, patterns, ignore_case = TRUE)
  expect_equal(length(result_insensitive), 2)
})