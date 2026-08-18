# add-startup-button.ps1
# Adds the Startup Manager button to the Config tab.

$target = ".\config\feature.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

# Make sure the function file is actually in place first.
$funcPath = ".\functions\public\Invoke-WPFStartupManager.ps1"
if (-not (Test-Path $funcPath)) {
    Write-Host ""
    Write-Host "ERROR: $funcPath is missing." -ForegroundColor Red
    Write-Host "Download Invoke-WPFStartupManager.ps1 and put it in the" -ForegroundColor Red
    Write-Host "functions\public folder before running this." -ForegroundColor Red
    exit 1
}
Write-Host "Found the startup manager function." -ForegroundColor Green

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "feature.json.startup.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$key = "WPFStartupManager"

if ($json.PSObject.Properties.Name -contains $key) {
    Write-Host ""
    Write-Host "Button already exists. Nothing changed." -ForegroundColor Yellow
    exit 0
}

$entry = [PSCustomObject]@{
    Content      = "Startup Manager"
    category     = "Note Tools"
    panel        = "2"
    Type         = "Button"
    ButtonWidth  = "300"
    Description  = "See every program that launches when Windows starts, and turn any of them off. Nothing is uninstalled - disabling is reversible."
    InvokeScript = @("Invoke-WPFStartupManager")
    link         = "https://noteshopp.mysellauth.com"
}

$json | Add-Member -NotePropertyName $key -NotePropertyValue $entry

$json | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $target -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - Startup Manager button added." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host "Then look on the Config tab for a 'Note Tools' section." -ForegroundColor White
Write-Host ""
