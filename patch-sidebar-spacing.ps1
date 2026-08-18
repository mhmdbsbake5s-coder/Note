# patch-sidebar-spacing.ps1
# Increases the gap between sidebar nav buttons.
# Change $Gap below if you want more or less.

$Gap = 16     # pixels between buttons
$Height = 44  # button height

$target = ".\xaml\inputXML.xaml"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "inputXML.xaml.spacing.backup") -Force

$text = Get-Content -LiteralPath $target -Raw

$pattern = '(?m)^(\s*<ToggleButton Style="\{StaticResource TabToggleButton\}" Margin=")[^"]*(" Height=")[^"]*(")'

$matchCount = ([regex]::Matches($text, $pattern)).Count

if ($matchCount -eq 0) {
    Write-Host ""
    Write-Host "ERROR: Could not find the sidebar buttons." -ForegroundColor Red
    Write-Host "Did patch-sidebar-fix.ps1 run successfully?" -ForegroundColor Red
    exit 1
}

$text = [regex]::Replace($text, $pattern, "`${1}0,0,0,$Gap`${2}$Height`${3}")

Set-Content -LiteralPath $target -Value $text -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - updated $matchCount buttons." -ForegroundColor Green
Write-Host "  gap between buttons: $Gap px" -ForegroundColor White
Write-Host "  button height: $Height px" -ForegroundColor White
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
Write-Host "Want more space? Open this script in Notepad, change the" -ForegroundColor Yellow
Write-Host "number on the `$Gap line at the top, save, and run it again." -ForegroundColor Yellow
Write-Host ""
