#include <Rcpp.h>
#include <map>
#include <vector>
#include <queue>

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