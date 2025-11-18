# Handler script to run the NAV Customization Analysis
# This script bypasses execution policy restrictions

Clear-Host

Write-Host "Starting NAV Customization Analysis..." -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $PSScriptRoot "Analyze-NAVCustomizations.ps1"

if (Test-Path $scriptPath) {
    # Execute the analysis script with bypass policy
    & powershell.exe -ExecutionPolicy Bypass -File $scriptPath
} else {
    Write-Host "ERROR: Could not find Analyze-NAVCustomizations.ps1" -ForegroundColor Red
    Write-Host "Expected location: $scriptPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")