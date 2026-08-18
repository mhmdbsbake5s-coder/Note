# fix-bundle-keys.ps1
# Adds the missing WPFInstall prefix to bundle entries in preset.json.

$presetPath = ".\config\preset.json"

if (-not (Test-Path $presetPath)) {
    Write-Host "ERROR: Could not find $presetPath" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $presetPath (Join-Path $backupDir "preset.json.keyfix.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green
Write-Host ""

$preset = Get-Content -LiteralPath $presetPath -Raw | ConvertFrom-Json

$bundleNames = @("Essentials","Gaming","Development","Media")
$fixedTotal = 0

foreach ($name in $bundleNames) {
    if ($preset.PSObject.Properties.Name -notcontains $name) {
        Write-Host "  $name - not present, skipping" -ForegroundColor Yellow
        continue
    }

    $entries = @($preset.$name)
    $newList = New-Object System.Collections.Generic.List[string]
    $fixed = 0

    foreach ($e in $entries) {
        if ([string]::IsNullOrWhiteSpace($e)) { continue }
        if ($e -match '^WPF(Install|Tweaks|Toggle|Feature|Appx)') {
            $newList.Add($e)
        } else {
            $newList.Add("WPFInstall$e")
            $fixed++
        }
    }

    $preset.$name = $newList.ToArray()
    Write-Host "$name - $($newList.Count) apps, $fixed prefixed" -ForegroundColor Green
    foreach ($k in $newList) { Write-Host "    $k" }
    Write-Host ""
    $fixedTotal += $fixed
}

$preset | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $presetPath -Encoding UTF8

Write-Host "DONE - $fixedTotal keys corrected." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
