# GraphFast Package Build Script for Windows
# Run this script in PowerShell to build and install the package

Write-Host "=== GraphFast Package Build Script ===" -ForegroundColor Green
Write-Host ""

# Check if R is in PATH
try {
    $rVersion = & R --version 2>$null
    Write-Host "Found R installation" -ForegroundColor Green
} catch {
    Write-Host "Error: R not found in PATH. Please install R and add it to your PATH." -ForegroundColor Red
    exit 1
}

# Check if Rtools is available (needed for package compilation)
$rtoolsCheck = & R -e "cat(pkgbuild::has_rtools())" 2>$null
if ($rtoolsCheck -ne "TRUE") {
    Write-Host "Warning: Rtools not detected. You may need to install Rtools for package compilation." -ForegroundColor Yellow
    Write-Host "Download from: https://cran.r-project.org/bin/windows/Rtools/" -ForegroundColor Yellow
}

# Run the R build script
Write-Host "Running R build script..." -ForegroundColor Green
& R --slave -f build_package.R

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build Complete ===" -ForegroundColor Green
    Write-Host "The graphfast package has been successfully built and installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now use the package in R with:" -ForegroundColor Cyan
    Write-Host "  library(graphfast)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To run the demo:" -ForegroundColor Cyan  
    Write-Host "  source('examples/demo.R')" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "=== Build Failed ===" -ForegroundColor Red
    Write-Host "There were errors during the build process." -ForegroundColor Red
    Write-Host "Please check the output above for details." -ForegroundColor Red
}