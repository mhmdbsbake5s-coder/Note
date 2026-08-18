# find-branding.ps1
# Scans the repo for leftover original-author branding.
# READ ONLY - this script changes nothing. It only reports.

$patterns = @(
    'ChrisTitusTech',
    'christitus',
    'Chris Titus',
    'ctt\.',
    'CTT',
    'titus'
)

$extensions = @('*.ps1','*.psm1','*.xaml','*.json','*.md','*.yml','*.yaml','*.bat','*.xml','*.txt','*.astro','*.mdx','*.js','*.ts','*.css','*.html')

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

Write-Host ""
Write-Host "Scanning: $root" -ForegroundColor Cyan
Write-Host ""

$files = Get-ChildItem -Path $root -Recurse -Include $extensions -File |
    Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and
        $_.Name -ne 'LICENSE' -and
        $_.Name -ne 'find-branding.ps1' -and
        $_.Name -ne 'rebrand-to-note.ps1'
    }

$results = @()

foreach ($file in $files) {
    $lineNum = 0
    foreach ($line in (Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue)) {
        $lineNum++
        foreach ($p in $patterns) {
            if ($line -match $p) {
                $results += [PSCustomObject]@{
                    File = $file.FullName.Replace($root, '.')
                    Line = $lineNum
                    Text = $line.Trim()
                }
                break
            }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No branding references found." -ForegroundColor Green
} else {
    Write-Host "Found $($results.Count) references:" -ForegroundColor Yellow
    Write-Host ""

    $results | Group-Object File | Sort-Object Count -Descending | ForEach-Object {
        Write-Host "--- $($_.Name)  [$($_.Count) hits]" -ForegroundColor Cyan
        $_.Group | ForEach-Object {
            $t = $_.Text
            if ($t.Length -gt 110) { $t = $t.Substring(0,110) + '...' }
            Write-Host "    line $($_.Line): $t"
        }
        Write-Host ""
    }

    $outFile = Join-Path $root 'branding-report.txt'
    $results | Format-Table -AutoSize | Out-File -FilePath $outFile -Width 300
    Write-Host "Full report saved to: $outFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "NOTE: The LICENSE file was deliberately skipped." -ForegroundColor Yellow
Write-Host "The original copyright notice must stay there - that is the MIT condition." -ForegroundColor Yellow
Write-Host ""
