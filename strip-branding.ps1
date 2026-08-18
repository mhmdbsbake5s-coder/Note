# strip-branding.ps1
# Removes remaining original-author branding.
# Backups go to .\_backups\ (outside the compiler's reach).

$ErrorActionPreference = "Stop"

$YourUser = "mhmdbsbake5s-coder"
$YourRepo = "note"
$YourSite = "https://noteshopp.mysellauth.com/"
$AuthorName = "Note"

$root = Get-Location
$backupDir = Join-Path $root "_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

Write-Host ""
Write-Host "=== Stage 1: remove the docs website ===" -ForegroundColor Cyan
if (Test-Path ".\docs") {
    Move-Item ".\docs" (Join-Path $backupDir "docs") -Force
    Write-Host "  docs folder moved to _backups\docs" -ForegroundColor Green
} else {
    Write-Host "  docs folder not found (already removed?)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Stage 2: remove funding config ===" -ForegroundColor Cyan
if (Test-Path ".\.github\FUNDING.yml") {
    Move-Item ".\.github\FUNDING.yml" (Join-Path $backupDir "FUNDING.yml") -Force
    Write-Host "  FUNDING.yml removed" -ForegroundColor Green
} else {
    Write-Host "  FUNDING.yml not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Stage 3: remove PowerShell Profile features ===" -ForegroundColor Cyan
$featPath = ".\config\feature.json"
if (Test-Path $featPath) {
    Copy-Item $featPath (Join-Path $backupDir "feature.json.backup") -Force
    $feat = Get-Content $featPath -Raw | ConvertFrom-Json
    $removed = 0
    $keys = @($feat.PSObject.Properties.Name)
    foreach ($k in $keys) {
        $entry = $feat.$k
        if ($entry.Content -and ($entry.Content -match 'PowerShell Profile')) {
            $feat.PSObject.Properties.Remove($k)
            $removed++
        }
    }
    $feat | ConvertTo-Json -Depth 20 | Set-Content $featPath -Encoding UTF8
    Write-Host "  removed $removed PowerShell Profile entries" -ForegroundColor Green
} else {
    Write-Host "  feature.json not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Stage 4: text replacements ===" -ForegroundColor Cyan

# Order matters - longest / most specific first.
$replacements = @(
    @('https://github.com/ChrisTitusTech/powershell-profile', "https://github.com/$YourUser/$YourRepo"),
    @('https://github.com/sponsors/ChrisTitusTech',           "https://github.com/$YourUser"),
    @('https://github.com/ChrisTitusTech/winutil',            "https://github.com/$YourUser/$YourRepo"),
    @('https://github.com/ChrisTitusTech/Note',               "https://github.com/$YourUser/$YourRepo"),
    @('https://github.com/ChrisTitusTech',                    "https://github.com/$YourUser"),
    @('ChrisTitusTech/winutil',                               "$YourUser/$YourRepo"),
    @('ChrisTitusTech/Note',                                  "$YourUser/$YourRepo"),
    @('https://Note.christitus.com',                          $YourSite.TrimEnd('/')),
    @('https://winutil.christitus.com',                       $YourSite.TrimEnd('/')),
    @('https://forum.christitus.com',                         $YourSite.TrimEnd('/')),
    @('https://www.cttstore.com/windows-toolbox',             $YourSite.TrimEnd('/')),
    @('https://www.cttstore.com',                             $YourSite.TrimEnd('/')),
    @('https://christitus.com',                               $YourSite.TrimEnd('/')),
    @('Note.christitus.com',                                  'noteshopp.mysellauth.com'),
    @('winutil.christitus.com',                               'noteshopp.mysellauth.com'),
    @('contact@christitus.com',                               ''),
    @('christitus.com',                                       'noteshopp.mysellauth.com'),
    @('Chris Titus @christitustech',                          $AuthorName),
    @('@ChrisTitusTech',                                      $AuthorName),
    @('ChrisTitusTech',                                       $AuthorName),
    @('christitustech',                                       $AuthorName),
    @('ChrisTitusTech',                                       $AuthorName),
    @('====Chris Titus Tech=====',                            "====$AuthorName====="),
    @("Chris Titus Tech's Windows Utility",                   $AuthorName),
    @('Chris Titus Tech',                                     $AuthorName),
    @('Chris Titus',                                          $AuthorName),
    @('CTT PowerShell Profile',                               'PowerShell Profile'),
    @('CTT logo preset',                                      'logo preset')
)

$extensions = @('*.ps1','*.psm1','*.xaml','*.json','*.md','*.yml','*.yaml','*.bat','*.xml','*.mdx','*.ts','*.astro','*.css','*.txt')

$files = Get-ChildItem -Path .\* -Recurse -File -Include $extensions |
    Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and
        $_.FullName -notmatch '\\_backups\\' -and
        $_.Name -ne 'LICENSE' -and
        $_.Name -ne 'Note.ps1' -and
        $_.Name -notlike '*.backup' -and
        $_.Name -ne 'strip-branding.ps1' -and
        $_.Name -ne 'find-branding.ps1' -and
        $_.Name -ne 'patch-logo.ps1' -and
        $_.Name -ne 'patch-theme.ps1' -and
        $_.Name -ne 'rebrand-to-note.ps1' -and
        $_.Name -ne 'package-lock.json'
    }

$filesChanged = 0
$totalSwaps = 0

foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $text) { continue }
    $orig = $text
    $swapsHere = 0

    foreach ($pair in $replacements) {
        $find = $pair[0]
        $to   = $pair[1]
        if ($text.Contains($find)) {
            $count = ([regex]::Matches($text, [regex]::Escape($find))).Count
            $text = $text.Replace($find, $to)
            $swapsHere += $count
        }
    }

    if ($text -ne $orig) {
        Set-Content -LiteralPath $file.FullName -Value $text -NoNewline -Encoding UTF8
        $filesChanged++
        $totalSwaps += $swapsHere
    }
}

Write-Host "  $totalSwaps replacements across $filesChanged files" -ForegroundColor Green

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Backups are in: $backupDir" -ForegroundColor Yellow
Write-Host "LICENSE was not touched (required by MIT)." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  .\Compile.ps1 -run     (rebuild and test)" -ForegroundColor White
Write-Host "  .\find-branding.ps1    (re-scan to see what is left)" -ForegroundColor White
Write-Host ""
