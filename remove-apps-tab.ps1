# remove-apps-tab.ps1
# Hides the Apps tab and makes Home the default landing tab.
# The TabItem stays in place - tab numbering is positional, so deleting
# it would break navigation for every other tab.

$xamlPath = ".\xaml\inputXML.xaml"

if (-not (Test-Path $xamlPath)) {
    Write-Host "ERROR: Could not find $xamlPath" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$backupFile = Join-Path $backupDir "inputXML.xaml.notabs.backup"
Copy-Item $xamlPath $backupFile -Force
Write-Host "Backup: $backupFile" -ForegroundColor Green
Write-Host ""

# ---------- 1. remove the Apps button ----------
$text = Get-Content -LiteralPath $xamlPath -Raw
$hadCRLF = $text.Contains("`r`n")
$text = $text -replace "`r`n", "`n"

$startIdx = $text.IndexOf('Name="WPFTab1BT"')

if ($startIdx -lt 0) {
    Write-Host "  Apps button not found - may already be removed." -ForegroundColor Yellow
} else {
    # walk back to the opening ToggleButton tag
    $openIdx = $text.LastIndexOf('<ToggleButton', $startIdx)
    # walk forward to the closing tag
    $closeIdx = $text.IndexOf('</ToggleButton>', $startIdx)

    if ($openIdx -lt 0 -or $closeIdx -lt 0) {
        Write-Host "  ERROR: could not determine the button boundaries." -ForegroundColor Red
        exit 1
    }

    $closeIdx += '</ToggleButton>'.Length
    # take any trailing blank line with it
    while ($closeIdx -lt $text.Length -and $text[$closeIdx] -eq "`n") { $closeIdx++ }

    $text = $text.Substring(0, $openIdx) + $text.Substring($closeIdx)
    Write-Host "  ok: removed the Apps button" -ForegroundColor Green
}

if ($hadCRLF) { $text = $text -replace "`n", "`r`n" }
Set-Content -LiteralPath $xamlPath -Value $text -NoNewline -Encoding UTF8

# ---------- 2. make Home the default tab ----------
Write-Host ""
Write-Host "Looking for the default startup tab..." -ForegroundColor Cyan

$candidates = Get-ChildItem -Path .\scripts, .\functions -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue |
    Select-String -Pattern 'WPFTab1BT' |
    Where-Object { $_.Path -notmatch '\\_backups\\' }

if (-not $candidates) {
    Write-Host "  No startup reference found." -ForegroundColor Yellow
    Write-Host "  If the app opens on a blank tab, tell me and I will fix it." -ForegroundColor Yellow
} else {
    foreach ($c in $candidates) {
        Write-Host "  found in $($c.Filename) line $($c.LineNumber)" -ForegroundColor White
        Copy-Item $c.Path (Join-Path $backupDir "$($c.Filename).notabs.backup") -Force
        $code = Get-Content -LiteralPath $c.Path -Raw
        $code = $code.Replace('"WPFTab1BT"', '"WPFTab7BT"')
        $code = $code.Replace("'WPFTab1BT'", "'WPFTab7BT'")
        Set-Content -LiteralPath $c.Path -Value $code -NoNewline -Encoding UTF8
        Write-Host "    changed to open on Home" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "SUCCESS - Apps tab hidden." -ForegroundColor Green
Write-Host ""
Write-Host "Note: the app bundle buttons lived on that tab, so they are" -ForegroundColor Yellow
Write-Host "no longer reachable either." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
Write-Host "To undo:" -ForegroundColor Yellow
Write-Host "  Copy-Item '$backupFile' '$xamlPath' -Force" -ForegroundColor White
Write-Host ""
