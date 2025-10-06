# Quick test of group_id function
# Run this after rebuilding the package

# Test data
test_data <- data.frame(
  id = 1:6,
  phone1 = c("123-456-7890", "987-654-3210", "123-456-7890", "", "555-0123", ""),
  phone2 = c("", "987-654-3210", "555-1234", "123-456-7890", "", "555-0123"),
  email = c("john@email.com", "jane@email.com", "john2@email.com", "john@email.com", "alice@email.com", "alice@email.com"),
  stringsAsFactors = FALSE
)

print("Test data:")
print(test_data)

# Test the C++ function directly
cat("\nTesting C++ function directly:\n")
result_cpp <- multi_column_group_cpp(
  data = list(test_data$phone1, test_data$phone2, test_data$email),
  incomparables = c(""),
  case_sensitive = TRUE,
  min_group_size = 1
)

print(result_cpp)

cat("\nGroup assignment:\n")
test_data$group_id <- result_cpp$group_ids
print(test_data)

cat("\nExpected groups:\n")
cat("- Group 1: rows 1,3,4 (share phone numbers)\n")
cat("- Group 2: row 2 (unique)\n") 
cat("- Group 3: rows 5,6 (share phone and email)\n")

# Verify results
groups <- split(test_data$id, test_data$group_id)
cat("\nActual groups:\n")
for(i in seq_along(groups)) {
  if(names(groups)[i] != "0") {
    cat(sprintf("Group %s: rows %s\n", names(groups)[i], paste(groups[[i]], collapse = ",")))
  }
}

cat("\n✓ C++ function test complete\n")