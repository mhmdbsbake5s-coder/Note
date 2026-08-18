# patch-fossinfo.ps1
# Removes the "Free and Open Source Software" heading from the install list.

$target = ".\config\appnavigation.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "appnavigation.json.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$removed = 0
foreach ($key in @($json.PSObject.Properties.Name)) {
    if ($key -eq 'WPFInstallFOSSInfo') {
        $json.PSObject.Properties.Remove($key)
        $removed++
    }
}

if ($removed -eq 0) {
    Write-Host ""
    Write-Host "WPFInstallFOSSInfo not found - may already be removed." -ForegroundColor Yellow
    Write-Host "Nothing changed." -ForegroundColor Yellow
    exit 0
}

$json | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $target -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - removed $removed entry." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
