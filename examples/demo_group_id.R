# group_id Function Demo
# Advanced entity resolution and deduplication

library(graphfast)
library(data.table)

# =============================================================================
# Basic Example: Phone Number Matching
# =============================================================================

cat("=== Basic Phone Number Matching ===\n")

# Create sample data with duplicate phone numbers across columns
df_phones <- data.table(
  id = 1:8,
  name = c("John Smith", "Jane Doe", "J. Smith", "Bob Wilson", "Alice Brown", "John S.", "Jane D.", "Robert W."),
  phone1 = c("123-456-7890", "987-654-3210", "123-456-7890", "", "555-0123", "", "987-654-3210", ""),
  phone2 = c("", "987-654-3210", "555-1234", "123-456-7890", "", "123-456-7890", "", "999-888-7777"),
  phone3 = c("555-1234", "", "", "", "", "555-1234", "", ""),
  stringsAsFactors = FALSE
)

print("Original data:")
print(df_phones)

# Find groups based on shared phone numbers
group_ids <- group_id(df_phones, 
                      cols = c("phone1", "phone2", "phone3"), 
                      incomparables = c("", "NA", "Unknown"))
group_ids
# integer(0)

df_phones$group_id <- group_ids
print("\nData with group IDs:")
print(df_phones)

# Show detailed results
result_detailed <- group_id(df_phones, 
                           cols = c("phone1", "phone2", "phone3"), 
                           incomparables = c(""), 
                           return_details = TRUE)

print("\nDetailed grouping results:")
print(result_detailed)

# =============================================================================
# Advanced Example: Multi-Field Entity Resolution
# =============================================================================

cat("\n\n=== Advanced Entity Resolution ===\n")

# More complex data with emails, phones, and addresses
df_complex <- data.frame(
  customer_id = 1:12,
  first_name = c("John", "Jane", "J.", "Bob", "Alice", "Johnny", "Janet", "Robert", "Al", "John", "Jane", "Bob"),
  last_name = c("Smith", "Doe", "Smith", "Wilson", "Brown", "Smith", "Doe", "Wilson", "Brown", "Smith", "Doe", "Wilson"),
  email1 = c("john@email.com", "jane@email.com", "", "bob@email.com", "alice@email.com", 
             "john.smith@email.com", "jane@email.com", "", "al.brown@email.com", "", "", ""),
  email2 = c("", "", "j.smith@email.com", "", "", "", "", "robert.w@email.com", 
             "", "john@email.com", "j.doe@email.com", "bob@email.com"),
  phone = c("123-456-7890", "987-654-3210", "123-456-7890", "555-1111", "555-2222",
            "", "987-654-3210", "555-1111", "555-2222", "", "", ""),
  mobile = c("", "", "", "", "555-2222", "123-456-7890", "", "", "", "555-3333", "", "555-1111"),
  stringsAsFactors = FALSE
)

print("Complex customer data:")
print(df_complex)

# Group by email and phone fields
group_result <- group_id(df_complex, 
                        cols = c("email1", "email2", "phone", "mobile"),
                        incomparables = c("", "NA", "NULL", "Unknown"),
                        min_group_size = 2,  # Only groups with 2+ records
                        return_details = TRUE)

df_complex$group_id <- group_result$group_ids

print("\nGrouped customers (min_group_size = 2):")
print(df_complex[order(df_complex$group_id, df_complex$customer_id), ])

print("\nGrouping summary:")
cat("Total groups found:", group_result$n_groups, "\n")
cat("Group sizes:", paste(group_result$group_sizes, collapse = ", "), "\n")

# =============================================================================
# Case Sensitivity Example
# =============================================================================

cat("\n\n=== Case Sensitivity Testing ===\n")

df_case <- data.frame(
  id = 1:6,
  email1 = c("John@Email.COM", "jane@email.com", "JOHN@EMAIL.COM", "bob@test.com", "", "Jane@Email.Com"),
  email2 = c("", "Jane@Email.Com", "", "", "john@email.com", ""),
  stringsAsFactors = FALSE
)

print("Email data with mixed case:")
print(df_case)

# Case sensitive grouping
group_sensitive <- group_id(df_case, 
                           cols = c("email1", "email2"),
                           case_sensitive = TRUE,
                           incomparables = c(""))

# Case insensitive grouping
group_insensitive <- group_id(df_case, 
                             cols = c("email1", "email2"),
                             case_sensitive = FALSE,
                             incomparables = c(""))

df_case$group_sensitive <- group_sensitive
df_case$group_insensitive <- group_insensitive

print("\nComparison of case-sensitive vs case-insensitive grouping:")
print(df_case)

# =============================================================================
# Performance Test with Larger Data
# =============================================================================

cat("\n\n=== Performance Test ===\n")

# Generate larger dataset
set.seed(42)
n_large <- 10000

# Create some duplicate patterns
phone_pool <- c("123-456-7890", "987-654-3210", "555-1111", "555-2222", "555-3333", 
                "444-5555", "666-7777", "888-9999", "", "", "", "")
email_pool <- c("user1@email.com", "user2@email.com", "user3@email.com", "test@test.com",
                "admin@site.com", "", "", "", "NULL", "NA")

df_large <- data.frame(
  id = 1:n_large,
  phone1 = sample(phone_pool, n_large, replace = TRUE, prob = c(rep(0.08, 8), rep(0.1, 4))),
  phone2 = sample(phone_pool, n_large, replace = TRUE, prob = c(rep(0.06, 8), rep(0.13, 4))),
  email1 = sample(email_pool, n_large, replace = TRUE, prob = c(rep(0.15, 6), rep(0.1, 4))),
  email2 = sample(email_pool, n_large, replace = TRUE, prob = c(rep(0.12, 6), rep(0.13, 4))),
  stringsAsFactors = FALSE
)

print(paste("Testing with", n_large, "rows..."))

# Time the grouping operation
start_time <- Sys.time()

large_result <- group_id(df_large,
                        cols = c("phone1", "phone2", "email1", "email2"),
                        incomparables = c("", "NULL", "NA", "Unknown"),
                        min_group_size = 2,
                        return_details = TRUE)

end_time <- Sys.time()
elapsed <- as.numeric(end_time - start_time, units = "secs")

print(paste("Processed", n_large, "rows in", round(elapsed, 3), "seconds"))
print(paste("Rate:", round(n_large / elapsed, 0), "rows/second"))
print(paste("Found", large_result$n_groups, "groups"))
print(paste("Largest group size:", max(large_result$group_sizes)))

# Show distribution of group sizes
group_size_table <- table(large_result$group_sizes)
print("Group size distribution:")
print(group_size_table)

# =============================================================================
# Data.table Integration Example
# =============================================================================

if (requireNamespace("data.table", quietly = TRUE)) {
  cat("\n\n=== Data.table Integration ===\n")
  
  library(data.table)
  
  # Convert to data.table
  dt <- as.data.table(df_phones[, c("id", "name", "phone1", "phone2", "phone3")])
  
  print("Original data.table:")
  print(dt)
  
  # Add group IDs using the convenience function
  add_group_ids(dt, 
                cols = c("phone1", "phone2", "phone3"),
                group_col = "entity_id",
                incomparables = c(""))
  
  print("\nData.table with entity IDs:")
  print(dt)
  
  # Group by entity and show summary
  dt_summary <- dt[, .(
    n_records = .N,
    names = paste(unique(name), collapse = "; "),
    phones = paste(unique(c(phone1[phone1 != ""], phone2[phone2 != ""], phone3[phone3 != ""])), collapse = "; ")
  ), by = entity_id][entity_id > 0]
  
  print("\nEntity summary (grouped records only):")
  print(dt_summary)
  
} else {
  cat("\n\ndata.table not available - skipping integration example\n")
}

cat("\n=== Demo Complete ===\n")
cat("The group_id function provides:\n")
cat("- High-performance multi-column grouping\n")
cat("- Support for incomparable values\n")
cat("- Case-sensitive/insensitive matching\n")
cat("- Minimum group size filtering\n")
cat("- Detailed results with value mappings\n")
cat("- data.table integration\n")
cat("- Memory-efficient Union-Find algorithm\n")