<#
.SYNOPSIS
    Rebrands a cloned Note repo as "Note".
    Run this from the ROOT of your cloned fork (the "note" folder).

.NOTES
    - Does NOT touch LICENSE (keep MIT license + original copyright intact).
    - Safe to re-run; it's just text substitution.
    - Review the diff (git diff) before committing -- automated renames can
      occasionally hit something unintended (e.g. a URL you want to keep
      pointing at the original project, like an upstream doc link).
#>

param(
    [string]$RepoRoot = "."
)

$replacements = @(
    @{ From = "Note"; To = "Note" },
    @{ From = "Note";         To = "Note" },
    @{ From = "Note";                    To = "Note" },
    @{ From = "Note";                            To = "Note" },
    @{ From = "Note";                            To = "note" },
    @{ From = "yourdomain.example/note";                 To = "yourdomain.example/note" } # update once you host it
)

# File types to scan -- skip binaries, .git, and LICENSE
$extensions = @("*.ps1","*.psm1","*.xaml","*.json","*.md","*.yml","*.yaml","*.bat")

Write-Host "Scanning $RepoRoot for files to rebrand..." -ForegroundColor Cyan

$files = Get-ChildItem -Path $RepoRoot -Recurse -Include $extensions -File |
    Where-Object { $_.FullName -notmatch '\.git[\\/]' -and $_.Name -ne "LICENSE" }

$changedCount = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }

    $original = $content
    foreach ($r in $replacements) {
        $content = $content -replace [regex]::Escape($r.From), $r.To
    }

    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Rebranded: $($file.FullName)" -ForegroundColor Green
        $changedCount++
    }
}

Write-Host "`nDone. $changedCount file(s) updated." -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run 'git diff' and review every change."
Write-Host "  2. Rename any files/folders literally named 'Note*' by hand."
Write-Host "  3. Update README.md with attribution to the original project."
Write-Host "  4. Do NOT modify LICENSE -- MIT requires it stay intact."
Write-Host "  5. Test-run the script in a VM before trusting it on a real machine."
