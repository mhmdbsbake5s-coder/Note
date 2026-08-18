# patch-theme.ps1
# Converts themes.json to a pure black-and-white palette.
# Backup is saved to the ROOT folder (not config) so the compiler ignores it.

$target = ".\config\themes.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    Write-Host "Run this from your Note folder." -ForegroundColor Red
    exit 1
}

# --- backup to root, NOT into config ---
$backup = ".\themes.json.backup"
if (-not (Test-Path $backup)) {
    Copy-Item $target $backup
    Write-Host "Backup saved: $backup" -ForegroundColor Green
} else {
    Write-Host "Backup already exists: $backup" -ForegroundColor Yellow
}

# Keys that must keep strong contrast so the UI stays readable.
# Value = what to use in the Dark theme, and in the Light theme.
$overrides = @{
    "ToggleButtonOnColor"            = @{ Dark = "#FFFFFF"; Light = "#000000" }
    "ToggleButtonOffColor"           = @{ Dark = "#4A4A4A"; Light = "#B8B8B8" }
    "ProgressBarForegroundColor"     = @{ Dark = "#FFFFFF"; Light = "#000000" }
    "ButtonBackgroundPressedColor"   = @{ Dark = "#FFFFFF"; Light = "#000000" }
    "ButtonBackgroundMouseoverColor" = @{ Dark = "#3A3A3A"; Light = "#D0D0D0" }
    "CheckboxMouseOverColor"         = @{ Dark = "#9A9A9A"; Light = "#9A9A9A" }
    "LinkHoverForegroundColor"       = @{ Dark = "#FFFFFF"; Light = "#000000" }
}

function Convert-ToGrey {
    param([string]$hex)
    $h = $hex.TrimStart('#')
    if ($h.Length -eq 8) { $a = $h.Substring(0,2); $h = $h.Substring(2) } else { $a = "" }
    if ($h.Length -ne 6) { return $hex }
    $r = [Convert]::ToInt32($h.Substring(0,2),16)
    $g = [Convert]::ToInt32($h.Substring(2,2),16)
    $b = [Convert]::ToInt32($h.Substring(4,2),16)
    # perceptual luminance
    $lum = [Math]::Round(0.2126*$r + 0.7152*$g + 0.0722*$b)
    if ($lum -lt 0) { $lum = 0 }
    if ($lum -gt 255) { $lum = 255 }
    $v = ('{0:X2}' -f [int]$lum)
    return "#$a$v$v$v"
}

$lines = Get-Content -LiteralPath $target
$section = ""
$out = New-Object System.Collections.Generic.List[string]
$changed = 0

foreach ($line in $lines) {
    # track which theme block we are inside
    if ($line -match '^\s*"([A-Za-z0-9_]+)"\s*:\s*\{') {
        $section = $matches[1]
    }

    $newLine = $line

    if ($line -match '^\s*"([A-Za-z0-9_]+)"\s*:\s*"(#[0-9A-Fa-f]{6,8})"') {
        $key = $matches[1]
        $col = $matches[2]

        $replacement = $null

        if ($overrides.ContainsKey($key)) {
            if ($section -eq "Light" -and $overrides[$key].ContainsKey("Light")) {
                $replacement = $overrides[$key]["Light"]
            } elseif ($overrides[$key].ContainsKey("Dark")) {
                $replacement = $overrides[$key]["Dark"]
            }
        }

        if (-not $replacement) {
            $replacement = Convert-ToGrey $col
        }

        if ($replacement -ne $col) {
            $newLine = $line -replace [regex]::Escape($col), $replacement
            $changed++
        }
    }

    $out.Add($newLine)
}

Set-Content -LiteralPath $target -Value $out -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - $changed colors converted to monochrome." -ForegroundColor Green
Write-Host ""
Write-Host "Rebuild to see it:" -ForegroundColor Cyan
Write-Host "  .\Compile.ps1 -run" -ForegroundColor White
Write-Host ""
Write-Host "To undo: copy themes.json.backup back over config\themes.json" -ForegroundColor Yellow
Write-Host ""
