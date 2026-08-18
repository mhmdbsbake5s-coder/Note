# fix-branding.ps1
# Stage 4 only: the text replacements that failed before.
# Uses objects instead of nested arrays (PowerShell flattens those).

$YourUser = "mhmdbsbake5s-coder"
$YourRepo = "note"
$YourSite = "https://noteshopp.mysellauth.com"
$AuthorName = "Note"

$repo = "https://github.com/$YourUser/$YourRepo"
$profileUrl = "https://github.com/$YourUser"

$replacements = New-Object System.Collections.Generic.List[PSObject]

function Add-Rule {
    param([string]$From, [string]$To)
    $replacements.Add([PSCustomObject]@{ From = $From; To = $To })
}

# Longest / most specific first.
Add-Rule 'https://github.com/ChrisTitusTech/powershell-profile' $repo
Add-Rule 'https://github.com/sponsors/ChrisTitusTech'           $profileUrl
Add-Rule 'https://github.com/ChrisTitusTech/winutil'            $repo
Add-Rule 'https://github.com/ChrisTitusTech/Note'               $repo
Add-Rule 'https://github.com/ChrisTitusTech'                    $profileUrl
Add-Rule 'ChrisTitusTech/winutil'                               "$YourUser/$YourRepo"
Add-Rule 'ChrisTitusTech/Note'                                  "$YourUser/$YourRepo"
Add-Rule 'https://Note.christitus.com'                          $YourSite
Add-Rule 'https://winutil.christitus.com'                       $YourSite
Add-Rule 'https://forum.christitus.com'                         $YourSite
Add-Rule 'https://www.cttstore.com/windows-toolbox'             $YourSite
Add-Rule 'https://www.cttstore.com'                             $YourSite
Add-Rule 'https://christitus.com'                               $YourSite
Add-Rule 'Note.christitus.com'                                  'noteshopp.mysellauth.com'
Add-Rule 'winutil.christitus.com'                               'noteshopp.mysellauth.com'
Add-Rule 'contact@christitus.com'                               ''
Add-Rule 'christitus.com'                                       'noteshopp.mysellauth.com'
Add-Rule 'Chris Titus @christitustech'                          $AuthorName
Add-Rule '@ChrisTitusTech'                                      $AuthorName
Add-Rule 'ChrisTitusTech'                                       $AuthorName
Add-Rule 'christitustech'                                       $AuthorName
Add-Rule '====Chris Titus Tech====='                            "====$AuthorName====="
Add-Rule "Chris Titus Tech's Windows Utility"                   $AuthorName
Add-Rule 'Chris Titus Tech'                                     $AuthorName
Add-Rule 'Chris Titus'                                          $AuthorName
Add-Rule 'CTT PowerShell Profile'                               'PowerShell Profile'
Add-Rule 'CTT logo preset'                                      'logo preset'

Write-Host ""
Write-Host "Loaded $($replacements.Count) replacement rules." -ForegroundColor Cyan

$extensions = @('.ps1','.psm1','.xaml','.json','.md','.yml','.yaml','.bat','.xml','.mdx','.ts','.astro','.css','.txt')

$skipNames = @(
    'LICENSE','Note.ps1','package-lock.json',
    'strip-branding.ps1','find-branding.ps1','fix-branding.ps1',
    'patch-logo.ps1','patch-theme.ps1','rebrand-to-note.ps1'
)

$files = Get-ChildItem -Path . -Recurse -File |
    Where-Object {
        $extensions -contains $_.Extension -and
        $_.FullName -notmatch '\\\.git\\' -and
        $_.FullName -notmatch '\\_backups\\' -and
        $skipNames -notcontains $_.Name -and
        $_.Name -notlike '*.backup'
    }

Write-Host "Scanning $($files.Count) files..." -ForegroundColor Cyan
Write-Host ""

$filesChanged = 0
$totalSwaps = 0
$changedList = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($text)) { continue }

    $orig = $text
    $swapsHere = 0

    foreach ($rule in $replacements) {
        if ($text.Contains($rule.From)) {
            $count = ([regex]::Matches($text, [regex]::Escape($rule.From))).Count
            $text = $text.Replace($rule.From, $rule.To)
            $swapsHere += $count
        }
    }

    if ($text -ne $orig) {
        Set-Content -LiteralPath $file.FullName -Value $text -NoNewline -Encoding UTF8
        $filesChanged++
        $totalSwaps += $swapsHere
        $changedList.Add("  $($file.FullName.Replace($PWD.Path,'.')) [$swapsHere]")
    }
}

if ($filesChanged -gt 0) {
    Write-Host "Changed files:" -ForegroundColor Green
    $changedList | ForEach-Object { Write-Host $_ }
}

Write-Host ""
Write-Host "DONE - $totalSwaps replacements across $filesChanged files" -ForegroundColor Green
Write-Host "LICENSE untouched (required by MIT)." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
