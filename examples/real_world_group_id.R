# Real-world group_id Example: Customer Deduplication
# Simulates a typical customer database deduplication scenario

library(graphfast)
if (requireNamespace("data.table", quietly = TRUE)) {
  library(data.table)
}

set.seed(42)

# =============================================================================
# Create Realistic Customer Database with Duplicates
# =============================================================================

cat("=== Creating Realistic Customer Database ===\n")

# Base customer profiles
base_customers <- list(
  list(first = "John", last = "Smith", email = "john.smith@email.com", phone = "123-456-7890"),
  list(first = "Jane", last = "Doe", email = "jane.doe@company.com", phone = "987-654-3210"),
  list(first = "Robert", last = "Johnson", email = "rob.johnson@test.com", phone = "555-111-2222"),
  list(first = "Mary", last = "Williams", email = "mary.williams@site.org", phone = "444-333-5555"),
  list(first = "Michael", last = "Brown", email = "mike.brown@email.com", phone = "666-777-8888"),
  list(first = "Lisa", last = "Davis", email = "lisa.davis@company.com", phone = "999-000-1111"),
  list(first = "David", last = "Miller", email = "david.miller@test.com", phone = "222-333-4444"),
  list(first = "Susan", last = "Wilson", email = "susan.wilson@site.org", phone = "777-888-9999")
)

# Generate variations and duplicates
customers <- data.frame(
  customer_id = integer(),
  first_name = character(),
  last_name = character(),
  email_primary = character(),
  email_secondary = character(),
  phone_home = character(),
  phone_mobile = character(),
  phone_work = character(),
  source_system = character(),
  stringsAsFactors = FALSE
)

customer_id <- 1
systems <- c("CRM", "ERP", "Website", "Support", "Sales")

for (base in base_customers) {
  # Create 2-4 variations of each customer
  n_variations <- sample(2:4, 1)
  
  for (i in 1:n_variations) {
    # Name variations
    first_variations <- c(
      base$first,
      substr(base$first, 1, 1),  # First initial
      paste0(substr(base$first, 1, 1), "."),  # First initial with period
      if (base$first == "Robert") "Bob" else if (base$first == "Michael") "Mike" else base$first,
      if (base$first == "Susan") "Sue" else base$first
    )
    
    last_variations <- c(
      base$last,
      toupper(base$last),  # All caps
      paste0(substr(base$last, 1, 1), ".")  # Last initial
    )
    
    # Email variations
    email_base <- strsplit(base$email, "@")[[1]]
    email_variations <- c(
      base$email,
      paste0(email_base[1], "+old@", email_base[2]),  # Plus addressing
      paste0(substr(email_base[1], 1, 3), "***@", email_base[2]),  # Masked
      gsub("\\.", "", base$email),  # No dots
      toupper(base$email),  # Different case
      ""  # Sometimes missing
    )
    
    # Phone variations
    clean_phone <- gsub("[^0-9]", "", base$phone)
    phone_variations <- c(
      base$phone,
      paste0("(", substr(clean_phone, 1, 3), ") ", substr(clean_phone, 4, 6), "-", substr(clean_phone, 7, 10)),
      paste0(substr(clean_phone, 1, 3), ".", substr(clean_phone, 4, 6), ".", substr(clean_phone, 7, 10)),
      clean_phone,  # No formatting
      paste0("1-", base$phone),  # With country code
      ""  # Sometimes missing
    )
    
    # Randomly assign variations to different fields
    new_customer <- data.frame(
      customer_id = customer_id,
      first_name = sample(first_variations, 1),
      last_name = sample(last_variations, 1),
      email_primary = sample(email_variations, 1),
      email_secondary = if (runif(1) < 0.3) sample(email_variations, 1) else "",
      phone_home = if (runif(1) < 0.7) sample(phone_variations, 1) else "",
      phone_mobile = if (runif(1) < 0.8) sample(phone_variations, 1) else "",
      phone_work = if (runif(1) < 0.4) sample(phone_variations, 1) else "",
      source_system = sample(systems, 1),
      stringsAsFactors = FALSE
    )
    
    customers <- rbind(customers, new_customer)
    customer_id <- customer_id + 1
  }
}

# Add some completely unique customers
for (i in 1:5) {
  unique_customer <- data.frame(
    customer_id = customer_id,
    first_name = paste0("Customer", i),
    last_name = paste0("Unique", i),
    email_primary = paste0("unique", i, "@random.com"),
    email_secondary = "",
    phone_home = paste0("800-", sprintf("%03d", i), "-", sprintf("%04d", i)),
    phone_mobile = "",
    phone_work = "",
    source_system = sample(systems, 1),
    stringsAsFactors = FALSE
  )
  
  customers <- rbind(customers, unique_customer)
  customer_id <- customer_id + 1
}

# Shuffle the data
customers <- customers[sample(nrow(customers)), ]
rownames(customers) <- NULL

cat(sprintf("Created database with %d customer records\n", nrow(customers)))
print(head(customers, 10))

# =============================================================================
# Perform Entity Resolution
# =============================================================================

cat("\n=== Performing Entity Resolution ===\n")

# Define columns to use for matching
email_cols <- c("email_primary", "email_secondary")
phone_cols <- c("phone_home", "phone_mobile", "phone_work")
all_contact_cols <- c(email_cols, phone_cols)

# Define incomparable values (things that shouldn't be used for matching)
incomparables <- c("", "NA", "NULL", "unknown", "***", "MASKED")

# Perform grouping with detailed results
start_time <- Sys.time()

result <- group_id(customers,
                   cols = all_contact_cols,
                   incomparables = incomparables,
                   case_sensitive = FALSE,  # Email/phone matching should be case-insensitive
                   min_group_size = 2,      # Only interested in groups with 2+ records
                   return_details = TRUE)

end_time <- Sys.time()
elapsed <- as.numeric(end_time - start_time, units = "secs")

customers$entity_id <- result$group_ids

cat(sprintf("Entity resolution completed in %.3f seconds\n", elapsed))
cat(sprintf("Found %d entities from %d records\n", result$n_groups, nrow(customers)))
cat(sprintf("Potential duplicates: %d records in %d groups\n", 
            sum(result$group_sizes), result$n_groups))

# =============================================================================
# Analyze Results
# =============================================================================

cat("\n=== Analyzing Results ===\n")

# Show duplicate groups
duplicate_customers <- customers[customers$entity_id > 0, ]
duplicate_customers <- duplicate_customers[order(duplicate_customers$entity_id, duplicate_customers$customer_id), ]

cat("Detected duplicate groups:\n")
for (entity in unique(duplicate_customers$entity_id)) {
  entity_records <- duplicate_customers[duplicate_customers$entity_id == entity, ]
  
  cat(sprintf("\nEntity %d (%d records):\n", entity, nrow(entity_records)))
  
  # Show the records in this group
  for (i in 1:nrow(entity_records)) {
    r <- entity_records[i, ]
    cat(sprintf("  [%d] %s %s | %s | %s | %s\n",
                r$customer_id,
                r$first_name,
                r$last_name,
                ifelse(r$email_primary != "", r$email_primary, "(no email)"),
                ifelse(r$phone_home != "", r$phone_home, 
                       ifelse(r$phone_mobile != "", r$phone_mobile, "(no phone)")),
                r$source_system))
  }
  
  # Show what values caused this grouping
  entity_customers <- customers[customers$entity_id == entity, ]
  matching_values <- c()
  
  for (col in all_contact_cols) {
    values <- unique(entity_customers[[col]])
    values <- values[!values %in% incomparables & values != ""]
    if (length(values) > 0) {
      matching_values <- c(matching_values, paste0(col, ":", values))
    }
  }
  
  if (length(matching_values) > 0) {
    cat(sprintf("  Matching on: %s\n", paste(matching_values, collapse = ", ")))
  }
}

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total customer records: %d\n", nrow(customers)))
cat(sprintf("Unique entities found: %d\n", length(unique(customers$entity_id[customers$entity_id > 0])) + sum(customers$entity_id == 0)))
cat(sprintf("Records in duplicate groups: %d\n", sum(customers$entity_id > 0)))
cat(sprintf("Singleton records: %d\n", sum(customers$entity_id == 0)))

# Group size distribution
group_sizes <- table(table(customers$entity_id[customers$entity_id > 0]))
cat(sprintf("Group size distribution:\n"))
for (size in names(group_sizes)) {
  cat(sprintf("  %s records per group: %d groups\n", size, group_sizes[size]))
}

# Show most frequently matched values
cat(sprintf("\nMost frequently matched values:\n"))
value_counts <- sort(sapply(result$value_map, length), decreasing = TRUE)
for (i in 1:min(5, length(value_counts))) {
  value <- names(value_counts)[i]
  count <- value_counts[i]
  cat(sprintf("  '%s': connects %d records\n", value, count))
}

# =============================================================================
# Export Results (if data.table available)
# =============================================================================

if (requireNamespace("data.table", quietly = TRUE)) {
  cat("\n=== Exporting Results with data.table ===\n")
  
  # Convert to data.table for efficient processing
  dt <- as.data.table(customers)
  
  # Create master record for each entity (pick first record with most complete data)
  master_records <- dt[entity_id > 0, .SD[which.max(
    (!is.na(email_primary) & email_primary != "") + 
    (!is.na(phone_home) & phone_home != "") + 
    (!is.na(phone_mobile) & phone_mobile != "")
  )], by = entity_id]
  
  # Add master flag
  dt[, is_master := FALSE]
  dt[master_records, is_master := TRUE, on = "customer_id"]
  
  # Create summary
  entity_summary <- dt[entity_id > 0, .(
    n_records = .N,
    master_customer_id = customer_id[is_master == TRUE][1],
    master_name = paste(first_name[is_master == TRUE][1], last_name[is_master == TRUE][1]),
    all_emails = paste(unique(c(email_primary, email_secondary)[c(email_primary, email_secondary) != ""]), collapse = "; "),
    all_phones = paste(unique(c(phone_home, phone_mobile, phone_work)[c(phone_home, phone_mobile, phone_work) != ""]), collapse = "; "),
    source_systems = paste(unique(source_system), collapse = ", ")
  ), by = entity_id]
  
  cat("Entity summary (first 10 entities):\n")
  print(head(entity_summary, 10))
  
  cat(sprintf("\nProcessed %d records into %d unique entities\n", 
              nrow(dt), nrow(entity_summary) + sum(dt$entity_id == 0)))
}

cat("\n=== Entity Resolution Complete ===\n")
cat("This example demonstrates:\n")
cat("- Realistic customer data variations\n")
cat("- Multi-field entity resolution\n")
cat("- Handling of incomparable values\n")
cat("- Case-insensitive matching\n")
cat("- Minimum group size filtering\n")
cat("- Performance on medium-sized datasets\n")
cat("- Integration with data.table for downstream processing\n")