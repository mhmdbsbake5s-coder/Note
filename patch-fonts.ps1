# patch-fonts.ps1
# Body text: Bahnschrift (condensed, technical)
# Headers:   Cascadia Mono (terminal feel)
# Both ship with Windows 11. Fallbacks listed for Windows 10.

$BodyFont   = "Bahnschrift, Segoe UI Variable Text, Segoe UI, Arial"
$HeaderFont = "Cascadia Mono, Consolas, Segoe UI"

$target = ".\config\themes.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "themes.json.fonts.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$fonts = @{
    "FontFamily"       = $BodyFont
    "ButtonFontFamily" = $BodyFont
    "HeaderFontFamily" = $HeaderFont

    # Bahnschrift is condensed, so it reads smaller at the same point size.
    # Nudging sizes up keeps it comfortable.
    "FontSize"         = "14"
    "AppEntryFontSize" = "14"
    "ButtonFontSize"   = "13"
    "TabButtonFontSize" = "15"
    "HeaderFontSize"   = "16"
}

$changed = 0
foreach ($key in $fonts.Keys) {
    if ($json.shared.PSObject.Properties.Name -contains $key) {
        $old = $json.shared.$key
        $json.shared.$key = $fonts[$key]
        Write-Host ("  {0}: {1} -> {2}" -f $key, $old, $fonts[$key])
    } else {
        $json.shared | Add-Member -NotePropertyName $key -NotePropertyValue $fonts[$key] -Force
        Write-Host ("  {0}: (added) {1}" -f $key, $fonts[$key])
    }
    $changed++
}

$json | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $target -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - $changed font values set." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
Write-Host "If text looks too small or too large, open this file in" -ForegroundColor Yellow
Write-Host "Notepad and adjust the FontSize numbers, then run it again." -ForegroundColor Yellow
Write-Host ""
