# patch-logo.ps1
# Replaces the in-app logo vector with the "N" monogram.
# Makes a backup first. Run from your Note folder.

$target = ".\functions\private\Invoke-WinUtilAssets.ps1"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    Write-Host "Make sure you are running this from your Note folder." -ForegroundColor Red
    exit 1
}

# --- backup ---
$backup = "$target.backup"
if (-not (Test-Path $backup)) {
    Copy-Item $target $backup
    Write-Host "Backup saved: $backup" -ForegroundColor Green
} else {
    Write-Host "Backup already exists, leaving it alone: $backup" -ForegroundColor Yellow
}

$text = Get-Content -LiteralPath $target -Raw

# --- the replacement block ---
$newBlock = @'
        'logo' {
            $LogoBadge = New-Object Windows.Shapes.Rectangle
            $LogoBadge.Width = 100
            $LogoBadge.Height = 100
            $LogoBadge.RadiusX = 22
            $LogoBadge.RadiusY = 22
            $LogoBadge.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#000000")
            [Windows.Controls.Canvas]::SetLeft($LogoBadge, 0)
            [Windows.Controls.Canvas]::SetTop($LogoBadge, 0)

            $LogoPathData1 = @"
M59.4478 76.0 36.7878 35.9574Q37.4521 41.7885 37.4521 45.3314V76.0H27.7828V24.0H40.2200L63.2122 64.3747Q62.5479 58.8020 62.5479 54.2257V24.0H72.2172V76.0Z
"@
            $LogoPath1 = New-Object Windows.Shapes.Path
            $LogoPath1.Data = [Windows.Media.Geometry]::Parse($LogoPathData1)
            $LogoPath1.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

            $canvas.Children.Add($LogoBadge) | Out-Null
            $canvas.Children.Add($LogoPath1) | Out-Null
        }
'@

# --- find and replace the old logo case ---
$pattern = "(?s)'logo'\s*\{.*?\`$canvas\.Children\.Add\(\`$LogoPath3\)\s*\|\s*Out-Null\s*\r?\n\s*\}"

if ($text -notmatch $pattern) {
    Write-Host ""
    Write-Host "ERROR: Could not locate the original logo block." -ForegroundColor Red
    Write-Host "The file may already be patched, or its structure differs." -ForegroundColor Red
    Write-Host "Nothing was changed." -ForegroundColor Red
    exit 1
}

$text = [regex]::Replace($text, $pattern, { param($m) $newBlock }, 'Singleline')

Set-Content -LiteralPath $target -Value $text -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - logo replaced." -ForegroundColor Green
Write-Host ""
Write-Host "Next: rebuild and look at the top-left of the window." -ForegroundColor Cyan
Write-Host "  .\Compile.ps1 -run" -ForegroundColor White
Write-Host ""
Write-Host "To undo: delete Invoke-WinUtilAssets.ps1 and rename the .backup file back." -ForegroundColor Yellow
Write-Host ""
