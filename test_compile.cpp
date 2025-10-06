#include <Rcpp.h>
#include <unordered_map>
#include <unordered_set>
#include <algorithm>
#include <vector>

// Simple test version of the function to verify compilation
// [[Rcpp::export]]
Rcpp::List test_multi_column_group_cpp(const Rcpp::List& data) {
    
    int n_rows = 0;
    int n_cols = data.size();
    
    if (n_cols == 0) {
        return Rcpp::List::create(
            Rcpp::Named("group_ids") = Rcpp::IntegerVector(),
            Rcpp::Named("n_groups") = 0
        );
    }
    
    // Get number of rows from first column
    if (data[0] != R_NilValue) {
        Rcpp::RObject first_col = data[0];
        if (first_col.isObject()) {
            n_rows = Rf_length(first_col);
        }
    }
    
    if (n_rows == 0) {
        return Rcpp::List::create(
            Rcpp::Named("group_ids") = Rcpp::IntegerVector(),
            Rcpp::Named("n_groups") = 0
        );
    }
    
    // Process first column only (simplified test)
    Rcpp::RObject column = data[0];
    
    if (column != R_NilValue && TYPEOF(column) == STRSXP) {
        Rcpp::CharacterVector char_col = Rcpp::as<Rcpp::CharacterVector>(column);
        int col_size = static_cast<int>(char_col.size());
        int max_rows = (n_rows < col_size) ? n_rows : col_size;
        
        // Simple grouping - just return sequential IDs
        std::vector<int> group_ids(n_rows);
        for (int i = 0; i < max_rows; i++) {
            group_ids[i] = i + 1;
        }
        
        return Rcpp::List::create(
            Rcpp::Named("group_ids") = group_ids,
            Rcpp::Named("n_groups") = max_rows
        );
    }
    
    // Default case
    std::vector<int> group_ids(n_rows, 1);
    return Rcpp::List::create(
        Rcpp::Named("group_ids") = group_ids,
        Rcpp::Named("n_groups") = 1
    );
}