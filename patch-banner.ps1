# patch-banner.ps1
# Replaces the console ASCII art banner with a NOTE wordmark.

$target = ".\scripts\main.ps1"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "main.ps1.banner.backup") -Force
Write-Host "Backup: $backupDir\main.ps1.banner.backup" -ForegroundColor Green

$text = Get-Content -LiteralPath $target -Raw

$newBanner = @'
Write-Host @"

##      ##     ######     ##########   ##########
####    ##   ##      ##       ##       ##
##  ##  ##   ##      ##       ##       ##
##    ####   ##      ##       ##       ########
##      ##   ##      ##       ##       ##
##      ##   ##      ##       ##       ##
##      ##     ######         ##       ##########

=====Windows Toolbox=====
"@
'@

# Match the whole Write-Host here-string containing the old art.
$pattern = '(?s)Write-Host\s+@"\s*\r?\n\s*CCCCCC.*?"@'

if ($text -notmatch $pattern) {
    Write-Host ""
    Write-Host "ERROR: Could not find the banner block." -ForegroundColor Red
    Write-Host "It may already be patched. Nothing was changed." -ForegroundColor Red
    exit 1
}

$text = [regex]::Replace($text, $pattern, { param($m) $newBanner }, 'Singleline')

Set-Content -LiteralPath $target -Value $text -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - banner replaced." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
