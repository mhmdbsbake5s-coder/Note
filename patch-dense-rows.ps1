# patch-dense-rows.ps1
# Turns the app card grid into a dense single-column list.

$EntryWidth = "980"   # wide enough to force one per row
$Margin     = "0,0,0,4"

$target = ".\config\themes.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "themes.json.rows.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$vals = @{
    "AppEntryWidth"           = $EntryWidth
    "AppEntryMargin"          = $Margin
    "AppEntryBorderThickness" = "0"
    "AppEntryIconSize"        = "24"
}

foreach ($key in $vals.Keys) {
    if ($json.shared.PSObject.Properties.Name -contains $key) {
        $old = $json.shared.$key
        $json.shared.$key = $vals[$key]
        Write-Host ("  {0}: {1} -> {2}" -f $key, $old, $vals[$key])
    } else {
        $json.shared | Add-Member -NotePropertyName $key -NotePropertyValue $vals[$key] -Force
        Write-Host ("  {0}: (added) {1}" -f $key, $vals[$key])
    }
}

$json | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $target -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - app entries are now full-width rows." -ForegroundColor Green
Write-Host ""
Write-Host "If they are too wide and cause sideways scrolling, lower" -ForegroundColor Yellow
Write-Host "`$EntryWidth at the top of this file and run it again." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
