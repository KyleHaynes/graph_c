#include <Rcpp.h>
#include <map>
#include <vector>
#include <queue>
#include <unordered_map>
#include <unordered_set>
#include <algorithm>

// Forward declarations to avoid conflicts
class UnionFind {
private:
    std::vector<int> parent;
    std::vector<int> rank;
    
public:
    UnionFind(int n) : parent(n), rank(n, 0) {
        for (int i = 0; i < n; i++) {
            parent[i] = i;
        }
    }
    
    int find(int x) {
        if (parent[x] != x) {
            parent[x] = find(parent[x]);
        }
        return parent[x];
    }
    
    bool union_sets(int x, int y) {
        int px = find(x);
        int py = find(y);
        
        if (px == py) return false;
        
        if (rank[px] < rank[py]) {
            parent[px] = py;
        } else if (rank[px] > rank[py]) {
            parent[py] = px;
        } else {
            parent[py] = px;
            rank[px]++;
        }
        return true;
    }
    
    bool connected(int x, int y) {
        return find(x) == find(y);
    }
};

//' Find Connected Components
// [[Rcpp::export]]
Rcpp::List find_components_cpp(const Rcpp::IntegerMatrix& edges, int n_nodes, bool compress = true) {
    UnionFind uf(n_nodes);
    
    for (int i = 0; i < edges.nrow(); i++) {
        int u = edges(i, 0) - 1;
        int v = edges(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes) {
            uf.union_sets(u, v);
        }
    }
    
    std::map<int, int> component_map;
    std::vector<int> components(n_nodes);
    int next_component_id = 0;
    
    for (int i = 0; i < n_nodes; i++) {
        int root = uf.find(i);
        if (component_map.find(root) == component_map.end()) {
            component_map[root] = compress ? next_component_id++ : root;
        }
        components[i] = component_map[root];
    }
    
    std::vector<int> component_sizes(next_component_id, 0);
    for (int comp : components) {
        if (compress) {
            component_sizes[comp]++;
        }
    }
    
    if (compress) {
        for (int& comp : components) {
            comp++;
        }
    }
    
    return Rcpp::List::create(
        Rcpp::Named("components") = components,
        Rcpp::Named("component_sizes") = component_sizes,
        Rcpp::Named("n_components") = next_component_id
    );
}

//' Check Connectivity
// [[Rcpp::export]]
Rcpp::LogicalVector are_connected_cpp(const Rcpp::IntegerMatrix& edges, const Rcpp::IntegerMatrix& query_pairs, int n_nodes) {
    UnionFind uf(n_nodes);
    
    for (int i = 0; i < edges.nrow(); i++) {
        int u = edges(i, 0) - 1;
        int v = edges(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes) {
            uf.union_sets(u, v);
        }
    }
    
    Rcpp::LogicalVector result(query_pairs.nrow());
    for (int i = 0; i < query_pairs.nrow(); i++) {
        int u = query_pairs(i, 0) - 1;
        int v = query_pairs(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes) {
            result[i] = uf.connected(u, v);
        } else {
            result[i] = false;
        }
    }
    
    return result;
}

//' Shortest Paths
// [[Rcpp::export]]
Rcpp::IntegerVector shortest_paths_cpp(const Rcpp::IntegerMatrix& edges, const Rcpp::IntegerMatrix& query_pairs, 
                                      int n_nodes, int max_distance) {
    
    std::vector<std::vector<int>> adj(n_nodes);
    
    for (int i = 0; i < edges.nrow(); i++) {
        int u = edges(i, 0) - 1;
        int v = edges(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes && u != v) {
            adj[u].push_back(v);
            adj[v].push_back(u);
        }
    }
    
    Rcpp::IntegerVector result(query_pairs.nrow());
    
    for (int q = 0; q < query_pairs.nrow(); q++) {
        int source = query_pairs(q, 0) - 1;
        int target = query_pairs(q, 1) - 1;
        
        if (source < 0 || source >= n_nodes || target < 0 || target >= n_nodes) {
            result[q] = -1;
            continue;
        }
        
        if (source == target) {
            result[q] = 0;
            continue;
        }
        
        std::vector<int> distance(n_nodes, -1);
        std::queue<int> bfs_queue;
        
        distance[source] = 0;
        bfs_queue.push(source);
        
        bool found = false;
        while (!bfs_queue.empty() && !found) {
            int current = bfs_queue.front();
            bfs_queue.pop();
            
            if (max_distance > 0 && distance[current] >= max_distance) {
                break;
            }
            
            for (int neighbor : adj[current]) {
                if (distance[neighbor] == -1) {
                    distance[neighbor] = distance[current] + 1;
                    
                    if (neighbor == target) {
                        result[q] = distance[neighbor];
                        found = true;
                        break;
                    }
                    
                    bfs_queue.push(neighbor);
                }
            }
        }
        
        if (!found) {
            result[q] = -1;
        }
    }
    
    return result;
}

//' Graph Statistics
// [[Rcpp::export]]
Rcpp::List graph_stats_cpp(const Rcpp::IntegerMatrix& edges, int n_nodes) {
    std::vector<int> degree(n_nodes, 0);
    int n_edges = edges.nrow();
    
    for (int i = 0; i < n_edges; i++) {
        int u = edges(i, 0) - 1;
        int v = edges(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes && u != v) {
            degree[u]++;
            degree[v]++;
        }
    }
    
    int min_degree = *std::min_element(degree.begin(), degree.end());
    int max_degree = *std::max_element(degree.begin(), degree.end());
    double mean_degree = 0.0;
    for (int d : degree) {
        mean_degree += d;
    }
    mean_degree /= n_nodes;
    
    double max_possible_edges = (double)n_nodes * (n_nodes - 1) / 2.0;
    double density = (max_possible_edges > 0) ? n_edges / max_possible_edges : 0.0;
    
    Rcpp::List degree_stats = Rcpp::List::create(
        Rcpp::Named("min") = min_degree,
        Rcpp::Named("max") = max_degree,
        Rcpp::Named("mean") = mean_degree
    );
    
    return Rcpp::List::create(
        Rcpp::Named("n_edges") = n_edges,
        Rcpp::Named("n_nodes") = n_nodes,
        Rcpp::Named("density") = density,
        Rcpp::Named("degree_stats") = degree_stats
    );
}

//' Get Edge Component Assignments
//' 
//' Efficiently returns component ID for each edge (both from and to nodes).
//' This is much faster than doing component lookup in R.
//' 
//' @param edges IntegerMatrix with two columns (from, to)
//' @param n_nodes Number of nodes in the graph
//' @param compress Whether to compress component IDs to consecutive integers
//' @return List with from_components and to_components vectors
// [[Rcpp::export]]
Rcpp::List get_edge_components_cpp(const Rcpp::IntegerMatrix& edges, int n_nodes, bool compress = true) {
    UnionFind uf(n_nodes);
    
    // Build the union-find structure
    for (int i = 0; i < edges.nrow(); i++) {
        int u = edges(i, 0) - 1;  // Convert to 0-based indexing
        int v = edges(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes) {
            uf.union_sets(u, v);
        }
    }
    
    // Create component mapping (same logic as find_components_cpp)
    std::map<int, int> component_map;
    std::vector<int> node_components(n_nodes);
    int next_component_id = 0;
    
    for (int i = 0; i < n_nodes; i++) {
        int root = uf.find(i);
        if (component_map.find(root) == component_map.end()) {
            component_map[root] = compress ? next_component_id++ : root;
        }
        node_components[i] = component_map[root];
    }
    
    // Convert to 1-based indexing if compressed
    if (compress) {
        for (int& comp : node_components) {
            comp++;
        }
    }
    
    // Now assign components directly to edges
    std::vector<int> from_components(edges.nrow());
    std::vector<int> to_components(edges.nrow());
    
    for (int i = 0; i < edges.nrow(); i++) {
        int u = edges(i, 0) - 1;  // Convert to 0-based
        int v = edges(i, 1) - 1;
        
        if (u >= 0 && u < n_nodes && v >= 0 && v < n_nodes) {
            from_components[i] = node_components[u];
            to_components[i] = node_components[v];
        } else {
            // Invalid node - assign -1 or 0
            from_components[i] = compress ? 0 : -1;
            to_components[i] = compress ? 0 : -1;
        }
    }
    
    return Rcpp::List::create(
        Rcpp::Named("from_components") = from_components,
        Rcpp::Named("to_components") = to_components,
        Rcpp::Named("n_components") = next_component_id
    );
}

//' Multi-Pattern Fixed String Matching
//'
//' Fast C++ implementation for finding multiple fixed patterns in strings.
//' Equivalent to multiple grepl(pattern, x, fixed=TRUE) calls but much faster.
//'
//' @param strings Character vector of strings to search in
//' @param patterns Character vector of fixed patterns to search for
//' @param match_any Logical. If TRUE, returns TRUE if ANY pattern matches.
//'   If FALSE, returns a matrix showing which pattern matches which string.
//' @param ignore_case Logical. Whether to ignore case when matching. Default FALSE.
//'
//' @return If match_any=TRUE: Logical vector same length as strings.
//'   If match_any=FALSE: Logical matrix with nrow=length(strings), ncol=length(patterns).
//'
//' @examples
//' strings <- c("hello world", "goodbye", "hello there", "world peace")
//' patterns <- c("hello", "world")
//' 
//' # Check if ANY pattern matches each string
//' multi_grepl_cpp(strings, patterns, match_any = TRUE)
//' # Returns: TRUE FALSE TRUE TRUE
//' 
//' # Get detailed matrix of which patterns match which strings
//' multi_grepl_cpp(strings, patterns, match_any = FALSE)
//' # Returns 4x2 matrix showing hello/world matches for each string
//'
// [[Rcpp::export]]
Rcpp::LogicalMatrix multi_grepl_cpp(const Rcpp::CharacterVector& strings,
                                   const Rcpp::CharacterVector& patterns,
                                   bool match_any = true,
                                   bool ignore_case = false) {
    
    int n_strings = strings.size();
    int n_patterns = patterns.size();
    
    // Convert patterns to std::string for easier manipulation
    std::vector<std::string> pattern_vec(n_patterns);
    for (int p = 0; p < n_patterns; p++) {
        pattern_vec[p] = Rcpp::as<std::string>(patterns[p]);
        if (ignore_case) {
            // Convert pattern to lowercase
            std::transform(pattern_vec[p].begin(), pattern_vec[p].end(), 
                         pattern_vec[p].begin(), ::tolower);
        }
    }
    
    if (match_any) {
        // Return vector indicating if ANY pattern matches each string
        Rcpp::LogicalVector result(n_strings);
        
        for (int i = 0; i < n_strings; i++) {
            std::string str = Rcpp::as<std::string>(strings[i]);
            if (ignore_case) {
                std::transform(str.begin(), str.end(), str.begin(), ::tolower);
            }
            
            bool found_match = false;
            for (int p = 0; p < n_patterns && !found_match; p++) {
                if (str.find(pattern_vec[p]) != std::string::npos) {
                    found_match = true;
                }
            }
            result[i] = found_match;
        }
        
        // Convert to matrix format for consistent return type
        Rcpp::LogicalMatrix result_matrix(n_strings, 1);
        for (int i = 0; i < n_strings; i++) {
            result_matrix(i, 0) = result[i];
        }
        return result_matrix;
        
    } else {
        // Return matrix showing which patterns match which strings
        Rcpp::LogicalMatrix result(n_strings, n_patterns);
        
        for (int i = 0; i < n_strings; i++) {
            std::string str = Rcpp::as<std::string>(strings[i]);
            if (ignore_case) {
                std::transform(str.begin(), str.end(), str.begin(), ::tolower);
            }
            
            for (int p = 0; p < n_patterns; p++) {
                result(i, p) = (str.find(pattern_vec[p]) != std::string::npos);
            }
        }
        
        return result;
    }
}

//' Multi-Pattern Fixed String Matching (Any Match)
//'
//' Simplified version that returns TRUE if any pattern matches each string.
//' Optimized for the common use case of "does this string contain any of these patterns?"
//'
//' @param strings Character vector of strings to search in
//' @param patterns Character vector of fixed patterns to search for
//' @param ignore_case Logical. Whether to ignore case. Default FALSE.
//'
//' @return Logical vector same length as strings
//'
// [[Rcpp::export]]
Rcpp::LogicalVector multi_grepl_any_cpp(const Rcpp::CharacterVector& strings,
                                        const Rcpp::CharacterVector& patterns,
                                        bool ignore_case = false) {
    
    int n_strings = strings.size();
    int n_patterns = patterns.size();
    
    // Convert patterns to std::string
    std::vector<std::string> pattern_vec(n_patterns);
    for (int p = 0; p < n_patterns; p++) {
        pattern_vec[p] = Rcpp::as<std::string>(patterns[p]);
        if (ignore_case) {
            std::transform(pattern_vec[p].begin(), pattern_vec[p].end(), 
                         pattern_vec[p].begin(), ::tolower);
        }
    }
    
    Rcpp::LogicalVector result(n_strings);
    
    for (int i = 0; i < n_strings; i++) {
        std::string str = Rcpp::as<std::string>(strings[i]);
        if (ignore_case) {
            std::transform(str.begin(), str.end(), str.begin(), ::tolower);
        }
        
        bool found_match = false;
        for (int p = 0; p < n_patterns && !found_match; p++) {
            if (str.find(pattern_vec[p]) != std::string::npos) {
                found_match = true;
            }
        }
        result[i] = found_match;
    }
    
    return result;
}

//' Multi-Pattern Fixed String Matching (Any Match) - Optimized Version
//'
//' High-performance version with multiple optimizations:
//' - Minimal string conversions using CHAR() and strstr()
//' - Pattern sorting by length for early termination  
//' - Chunked processing for better cache locality
//' - Optimized case conversion without std::transform
//'
//' @param strings Character vector of strings to search in
//' @param patterns Character vector of fixed patterns to search for
//' @param ignore_case Logical. Whether to ignore case. Default FALSE.
//'
//' @return Logical vector same length as strings
//'
// [[Rcpp::export]]
Rcpp::LogicalVector multi_grepl_any_fast_cpp(const Rcpp::CharacterVector& strings,
                                             const Rcpp::CharacterVector& patterns,
                                             bool ignore_case = false) {
    
    int n_strings = strings.size();
    int n_patterns = patterns.size();
    
    // Early exit for empty patterns
    if (n_patterns == 0) {
        return Rcpp::LogicalVector(n_strings, false);
    }
    
    // Convert and sort patterns by length (shorter first for faster rejection)
    std::vector<std::pair<std::string, int>> pattern_data;
    pattern_data.reserve(n_patterns);
    
    for (int p = 0; p < n_patterns; p++) {
        std::string pattern = Rcpp::as<std::string>(patterns[p]);
        if (ignore_case) {
            // Fast case conversion
            for (char& c : pattern) {
                if (c >= 'A' && c <= 'Z') {
                    c += 32;
                }
            }
        }
        pattern_data.emplace_back(std::move(pattern), pattern.length());
    }
    
    // Sort by length for early termination
    std::sort(pattern_data.begin(), pattern_data.end(), 
              [](const std::pair<std::string, int>& a, const std::pair<std::string, int>& b) { 
                  return a.second < b.second; 
              });
    
    Rcpp::LogicalVector result(n_strings);
    
    for (int i = 0; i < n_strings; i++) {
        const char* str_ptr = CHAR(strings[i]);
        int str_len = strlen(str_ptr);
        bool found_match = false;
        
        if (ignore_case) {
            // Convert string once
            std::string str_lower;
            str_lower.reserve(str_len);
            for (int j = 0; j < str_len; j++) {
                char c = str_ptr[j];
                str_lower += (c >= 'A' && c <= 'Z') ? (c + 32) : c;
            }
            
            // Search patterns
            for (size_t p = 0; p < pattern_data.size(); p++) {
                const std::pair<std::string, int>& pattern_pair = pattern_data[p];
                if (pattern_pair.second > str_len) break;
                if (str_lower.find(pattern_pair.first) != std::string::npos) {
                    found_match = true;
                    break;
                }
            }
        } else {
            // Case-sensitive: use fast C-style search
            for (size_t p = 0; p < pattern_data.size(); p++) {
                const std::pair<std::string, int>& pattern_pair = pattern_data[p];
                if (pattern_pair.second > str_len) break;
                if (strstr(str_ptr, pattern_pair.first.c_str()) != nullptr) {
                    found_match = true;
                    break;
                }
            }
        }
        
        result[i] = found_match;
    }
    
    return result;
}

//' Multi-Column Group ID Assignment
//'
//' High-performance grouping based on shared values across multiple columns.
//' Uses Union-Find with path compression for optimal performance.
//' Perfect for entity resolution, deduplication, and finding connected records.
//'
//' @param data List of character/numeric vectors representing columns to group by
//' @param incomparables Character vector of values to exclude from grouping (e.g., "", NA, "Unknown")
//' @param case_sensitive Logical. Whether string comparisons should be case sensitive. Default TRUE.
//' @param min_group_size Integer. Minimum group size to assign group ID (smaller groups get ID 0). Default 1.
//'
//' @return List containing:
//' \item{group_ids}{Integer vector of group IDs for each row}
//' \item{n_groups}{Total number of groups found}
//' \item{group_sizes}{Integer vector of group sizes}
//' \item{value_map}{List showing which values belong to which groups}
//'
//' @examples
//' # Phone number matching across columns
//' phone1 <- c("123-456-7890", "987-654-3210", "123-456-7890", "", "555-0123")
//' phone2 <- c("", "987-654-3210", "555-1234", "123-456-7890", "")
//' email <- c("john@email.com", "jane@email.com", "bob@email.com", "john@email.com", "alice@email.com")
//' 
//' result <- multi_column_group_cpp(list(phone1, phone2, email), 
//'                                  incomparables = c("", "NA", "Unknown"))
//'
// [[Rcpp::export]]
Rcpp::List multi_column_group_cpp(const Rcpp::List& data,
                                  const Rcpp::CharacterVector& incomparables = Rcpp::CharacterVector::create(),
                                  bool case_sensitive = true,
                                  int min_group_size = 1) {
    
    int n_rows = 0;
    int n_cols = data.size();
    
    if (n_cols == 0) {
        return Rcpp::List::create(
            Rcpp::Named("group_ids") = Rcpp::IntegerVector(),
            Rcpp::Named("n_groups") = 0,
            Rcpp::Named("group_sizes") = Rcpp::IntegerVector(),
            Rcpp::Named("value_map") = Rcpp::List()
        );
    }
    
    // Get number of rows from first non-null column
    for (int i = 0; i < n_cols && n_rows == 0; i++) {
        if (data[i] != R_NilValue) {
            Rcpp::RObject col = data[i];
            n_rows = Rf_length(col);
        }
    }
    
    if (n_rows == 0) {
        return Rcpp::List::create(
            Rcpp::Named("group_ids") = Rcpp::IntegerVector(),
            Rcpp::Named("n_groups") = 0,
            Rcpp::Named("group_sizes") = Rcpp::IntegerVector(),
            Rcpp::Named("value_map") = Rcpp::List()
        );
    }
    
    // Convert incomparables to set for fast lookup
    std::unordered_set<std::string> incomp_set;
    for (int i = 0; i < incomparables.size(); i++) {
        std::string val = Rcpp::as<std::string>(incomparables[i]);
        if (!case_sensitive) {
            std::transform(val.begin(), val.end(), val.begin(), ::tolower);
        }
        incomp_set.insert(val);
    }
    
    // Create value-to-rows mapping
    std::unordered_map<std::string, std::vector<int>> value_to_rows;
    
    // Process each column
    for (int col = 0; col < n_cols; col++) {
        Rcpp::RObject column = data[col];
        
        if (column == R_NilValue) continue;
        
        // Handle different column types
        if (TYPEOF(column) == STRSXP) {
            Rcpp::CharacterVector char_col = Rcpp::as<Rcpp::CharacterVector>(column);
            int col_size = static_cast<int>(char_col.size());
            int max_rows = (n_rows < col_size) ? n_rows : col_size;
            for (int row = 0; row < max_rows; row++) {
                if (char_col[row] == NA_STRING) continue;
                
                std::string val = Rcpp::as<std::string>(char_col[row]);
                if (!case_sensitive) {
                    std::transform(val.begin(), val.end(), val.begin(), ::tolower);
                }
                
                // Skip incomparable values
                if (incomp_set.find(val) != incomp_set.end()) continue;
                if (val.empty()) continue;
                
                value_to_rows[val].push_back(row);
            }
        } else if (TYPEOF(column) == REALSXP) {
            Rcpp::NumericVector num_col = Rcpp::as<Rcpp::NumericVector>(column);
            int col_size = static_cast<int>(num_col.size());
            int max_rows = (n_rows < col_size) ? n_rows : col_size;
            for (int row = 0; row < max_rows; row++) {
                if (Rcpp::NumericVector::is_na(num_col[row])) continue;
                
                std::string val = std::to_string(num_col[row]);
                value_to_rows[val].push_back(row);
            }
        } else if (TYPEOF(column) == INTSXP) {
            Rcpp::IntegerVector int_col = Rcpp::as<Rcpp::IntegerVector>(column);
            int col_size = static_cast<int>(int_col.size());
            int max_rows = (n_rows < col_size) ? n_rows : col_size;
            for (int row = 0; row < max_rows; row++) {
                if (int_col[row] == NA_INTEGER) continue;
                
                std::string val = std::to_string(int_col[row]);
                value_to_rows[val].push_back(row);
            }
        }
    }
    
    // Initialize Union-Find
    UnionFind uf(n_rows);
    
    // Union rows that share values
    for (const auto& pair : value_to_rows) {
        const std::vector<int>& rows = pair.second;
        if (rows.size() < 2) continue;  // Need at least 2 rows to form a group
        
        // Union all rows that share this value
        for (size_t i = 1; i < rows.size(); i++) {
            uf.union_sets(rows[0], rows[i]);
        }
    }
    
    // Assign group IDs
    std::unordered_map<int, int> root_to_group;
    std::vector<int> group_ids(n_rows, 0);
    std::vector<int> temp_group_sizes;
    int next_group_id = 1;
    
    // First pass: identify roots and count group sizes
    std::unordered_map<int, int> root_counts;
    for (int i = 0; i < n_rows; i++) {
        int root = uf.find(i);
        root_counts[root]++;
    }
    
    // Second pass: assign group IDs only to groups meeting minimum size
    for (int i = 0; i < n_rows; i++) {
        int root = uf.find(i);
        
        if (root_counts[root] >= min_group_size) {
            if (root_to_group.find(root) == root_to_group.end()) {
                root_to_group[root] = next_group_id++;
                temp_group_sizes.push_back(root_counts[root]);
            }
            group_ids[i] = root_to_group[root];
        } else {
            group_ids[i] = 0;  // Singleton or small group
        }
    }
    
    // Create value mapping for output
    Rcpp::List value_map;
    std::vector<std::string> map_names;
    
    for (const auto& pair : value_to_rows) {
        if (pair.second.size() >= 2) {  // Only include values that create groups
            map_names.push_back(pair.first);
            Rcpp::IntegerVector row_vector(static_cast<int>(pair.second.size()));
            // Copy values and convert to 1-based indexing for R
            for (size_t i = 0; i < pair.second.size(); i++) {
                row_vector[static_cast<int>(i)] = pair.second[i] + 1;
            }
            value_map.push_back(row_vector);
        }
    }
    value_map.names() = map_names;
    
    return Rcpp::List::create(
        Rcpp::Named("group_ids") = group_ids,
        Rcpp::Named("n_groups") = next_group_id - 1,
        Rcpp::Named("group_sizes") = temp_group_sizes,
        Rcpp::Named("value_map") = value_map
    );
}