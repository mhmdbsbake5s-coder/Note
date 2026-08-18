# add-bundles.ps1
# Adds app bundles to preset.json by matching against your actual app list.

$appsPath   = ".\config\applications.json"
$presetPath = ".\config\preset.json"

foreach ($p in @($appsPath, $presetPath)) {
    if (-not (Test-Path $p)) {
        Write-Host "ERROR: Could not find $p" -ForegroundColor Red
        exit 1
    }
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $presetPath (Join-Path $backupDir "preset.json.bundles.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green
Write-Host ""

$apps   = Get-Content -LiteralPath $appsPath -Raw | ConvertFrom-Json
$preset = Get-Content -LiteralPath $presetPath -Raw | ConvertFrom-Json

# All install checkbox keys available.
$allKeys = @($apps.PSObject.Properties.Name)

function Find-AppKey {
    param([string]$Needle)
    # try key name first, then the app's display content
    $hit = $allKeys | Where-Object { $_ -replace '^WPFInstall','' -ieq $Needle } | Select-Object -First 1
    if ($hit) { return $hit }
    $hit = $allKeys | Where-Object { $_ -imatch [regex]::Escape($Needle) } | Select-Object -First 1
    if ($hit) { return $hit }
    $hit = $allKeys | Where-Object {
        $c = $apps.$_.content
        $c -and ($c -imatch [regex]::Escape($Needle))
    } | Select-Object -First 1
    return $hit
}

# Bundles defined by what the app is called, not by guessed key names.
$bundles = [ordered]@{
    "Essentials" = @(
        "7-Zip", "Firefox", "VLC", "Notepad++", "PowerToys",
        "Everything", "ShareX", "qBittorrent", "Adobe Acrobat Reader"
    )
    "Gaming" = @(
        "Steam", "Discord", "Epic Games", "OBS Studio", "MSI Afterburner"
    )
    "Development" = @(
        "Visual Studio Code", "Git", "Windows Terminal", "Python", "Node"
    )
    "Media" = @(
        "VLC", "OBS Studio", "Audacity", "GIMP", "HandBrake", "mpv"
    )
}

$added = 0

foreach ($name in $bundles.Keys) {
    $found   = New-Object System.Collections.Generic.List[string]
    $missing = New-Object System.Collections.Generic.List[string]

    foreach ($app in $bundles[$name]) {
        $key = Find-AppKey $app
        if ($key) { $found.Add($key) } else { $missing.Add($app) }
    }

    Write-Host "$name" -ForegroundColor Cyan
    if ($found.Count -gt 0) {
        foreach ($f in $found) { Write-Host "    + $f" -ForegroundColor Green }
    }
    if ($missing.Count -gt 0) {
        foreach ($m in $missing) { Write-Host "    - not in your app list: $m" -ForegroundColor Yellow }
    }

    if ($found.Count -eq 0) {
        Write-Host "    skipped - nothing matched" -ForegroundColor Yellow
        Write-Host ""
        continue
    }

    $preset | Add-Member -NotePropertyName $name -NotePropertyValue $found.ToArray() -Force
    $added++
    Write-Host ""
}

$preset | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $presetPath -Encoding UTF8

Write-Host "DONE - $added bundles written to preset.json" -ForegroundColor Green
Write-Host ""
Write-Host "These are defined but not yet clickable - they need buttons," -ForegroundColor Yellow
Write-Host "which is the next step." -ForegroundColor Yellow
Write-Host ""
