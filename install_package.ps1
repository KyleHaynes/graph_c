# PowerShell script to install GraphFast package
Write-Host "=== GraphFast Package Installation ===" -ForegroundColor Green

# Change to package directory
Set-Location "c:\Users\kyleh\GitHub\graph_c"

# Run R installation script
Write-Host "Running R installation..." -ForegroundColor Yellow

# Try to find R executable
$rPaths = @(
    "C:\Program Files\R\R-4.5.0\bin\x64\R.exe",
    "C:\Program Files\R\R-4.4.2\bin\x64\R.exe", 
    "C:\Program Files\R\R-4.4.1\bin\x64\R.exe",
    "C:\Program Files\R\R-4.4.0\bin\x64\R.exe"
)

$rExe = $null
foreach ($path in $rPaths) {
    if (Test-Path $path) {
        $rExe = $path
        break
    }
}

if ($rExe) {
    Write-Host "Found R at: $rExe" -ForegroundColor Green
    
    # Run installation
    & "$rExe" --slave -f quick_install_test.R
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installation completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Installation had issues. Check output above." -ForegroundColor Yellow
    }
} else {
    Write-Host "Could not find R installation. Please ensure R is installed." -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Try using PATH
    try {
        R --slave -f quick_install_test.R
    } catch {
        Write-Host "R not found in PATH either. Please install R and add to PATH." -ForegroundColor Red
    }
}

Write-Host "`nInstallation script completed." -ForegroundColor Cyan