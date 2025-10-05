# GitHub Repository Setup Script for GraphFast Package
# Run this script to initialize git and prepare for GitHub upload

Write-Host "=== GraphFast GitHub Repository Setup ===" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
$currentPath = Get-Location
if (-not (Test-Path "DESCRIPTION") -or -not (Test-Path "src/graph_algorithms.cpp")) {
    Write-Host "Error: Please run this script from the GraphFast package root directory" -ForegroundColor Red
    Write-Host "Expected files: DESCRIPTION, src/graph_algorithms.cpp" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Found GraphFast package files" -ForegroundColor Green

# Check if git is installed
try {
    $gitVersion = git --version 2>$null
    Write-Host "✓ Git is installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Check if this is already a git repository
if (Test-Path ".git") {
    Write-Host "! This directory is already a git repository" -ForegroundColor Yellow
    $response = Read-Host "Do you want to reinitialize? This will preserve your files but reset git history (y/N)"
    if ($response.ToLower() -ne 'y') {
        Write-Host "Aborted. Use existing git repository." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item -Recurse -Force .git
}

# Initialize git repository
Write-Host "Initializing git repository..." -ForegroundColor Cyan
git init

# Create/update .gitignore
Write-Host "Creating .gitignore..." -ForegroundColor Cyan
@'
# R specific
.Rproj.user/
.Rhistory
.RData
.Ruserdata
*.Rproj

# Package building
/src/*.o
/src/*.so
/src/*.dll
/man/*.Rd
/R/RcppExports.R
/src/RcppExports.cpp

# Build artifacts
*.tar.gz
/check/
/build/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Temporary files
*~
*.tmp
*.temp

# Large test files (optional - remove if you want to commit test data)
*_test_large*
*_performance_large*

# Private/local configuration
.env
config_local.*
'@ | Out-File -FilePath ".gitignore" -Encoding UTF8

# Stage all files
Write-Host "Staging files for commit..." -ForegroundColor Cyan
git add .

# Check what will be committed
Write-Host "`nFiles to be committed:" -ForegroundColor Yellow
git status --porcelain

# Make initial commit
Write-Host "`nMaking initial commit..." -ForegroundColor Cyan
git commit -m "Initial commit: GraphFast R package

- High-performance graph analysis package using C++
- Connected components analysis with Union-Find algorithm
- Connectivity queries and shortest path computation
- Memory-efficient processing of massive graphs (40M+ edges)
- Comprehensive documentation and examples
- Performance testing and benchmarking tools

Features:
- Connected components: O(m×α(n)) time complexity
- Batch connectivity queries
- Multi-source shortest paths with BFS
- Graph statistics computation
- Memory optimization for sparse graphs
- Cross-platform compatibility (Windows/macOS/Linux)

Package structure:
- R/ : R interface functions
- src/ : Optimized C++ implementations
- tests/ : Unit tests and validation
- examples/ : Usage demonstrations
- vignettes/ : Detailed documentation
- performance_test.R : Large-scale performance benchmarking"

Write-Host "✓ Initial commit created" -ForegroundColor Green

# Show repository status
Write-Host "`n=== Repository Status ===" -ForegroundColor Cyan
git log --oneline -1
git status

Write-Host "`n=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Create a new repository on GitHub:"
Write-Host "   - Go to https://github.com/new"
Write-Host "   - Repository name: graphfast (or your preferred name)"
Write-Host "   - Description: High-performance graph analysis R package using C++"
Write-Host "   - Make it Public (recommended for R packages)"
Write-Host "   - Don't initialize with README (we already have files)"
Write-Host ""
Write-Host "2. Link this local repository to GitHub:"
Write-Host "   git remote add origin https://github.com/USERNAME/REPOSITORY.git"
Write-Host "   git branch -M main"
Write-Host "   git push -u origin main"
Write-Host ""
Write-Host "3. Example commands (replace USERNAME and REPOSITORY):"
Write-Host "   git remote add origin https://github.com/kyleh/graphfast.git" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Optional: Add GitHub-specific features:"
Write-Host "   - Enable GitHub Actions (CI/CD already configured in .github/)"
Write-Host "   - Add topics: r, rcpp, graph-algorithms, performance, cpp"
Write-Host "   - Create releases for package versions"
Write-Host ""
Write-Host "Repository is ready for GitHub!" -ForegroundColor Green