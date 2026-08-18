# add-license-check.ps1
# Runs the licence check before the app window opens.

$mainPath = ".\scripts\main.ps1"
$funcPath = ".\functions\private\Test-NoteLicense.ps1"

if (-not (Test-Path $mainPath)) {
    Write-Host "ERROR: Could not find $mainPath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $funcPath)) {
    Write-Host ""
    Write-Host "ERROR: $funcPath is missing." -ForegroundColor Red
    Write-Host "Put Test-NoteLicense.ps1 in functions\private first." -ForegroundColor Red
    exit 1
}
Write-Host "Found the licence function." -ForegroundColor Green

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$backupFile = Join-Path $backupDir "main.ps1.license.backup"
Copy-Item $mainPath $backupFile -Force
Write-Host "Backup: $backupFile" -ForegroundColor Green

$text = Get-Content -LiteralPath $mainPath -Raw

if ($text.Contains("Test-NoteLicense")) {
    Write-Host ""
    Write-Host "Licence check already present. Nothing changed." -ForegroundColor Yellow
    exit 0
}

# Insert right after the banner block, before anything else runs.
$anchor = '=====Windows Toolbox====='
$idx = $text.IndexOf($anchor)

if ($idx -lt 0) {
    Write-Host ""
    Write-Host "ERROR: could not find the banner block." -ForegroundColor Red
    Write-Host "Did patch-banner.ps1 run? Nothing changed." -ForegroundColor Red
    exit 1
}

# find the end of the here-string that follows
$endIdx = $text.IndexOf('"@', $idx)
if ($endIdx -lt 0) {
    Write-Host "ERROR: could not find the end of the banner." -ForegroundColor Red
    exit 1
}
$insertAt = $endIdx + 2

$check = @'


# ---- licence check ----
if (-not (Test-NoteLicense)) {
    Write-Host "No valid licence. Exiting." -ForegroundColor Yellow
    return
}
'@

$text = $text.Substring(0, $insertAt) + $check + $text.Substring($insertAt)

Set-Content -LiteralPath $mainPath -Value $text -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - licence check wired in." -ForegroundColor Green
Write-Host ""
Write-Host "Generate keys first:  .\make-keys.ps1" -ForegroundColor Cyan
Write-Host "Then:                 .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
Write-Host "To clear your own activation while testing:" -ForegroundColor Yellow
Write-Host "  Remove-Item 'HKCU:\Software\Note\License' -Recurse -Force" -ForegroundColor White
Write-Host ""
Write-Host "To remove the check entirely:" -ForegroundColor Yellow
Write-Host "  Copy-Item '$backupFile' '$mainPath' -Force" -ForegroundColor White
Write-Host ""
