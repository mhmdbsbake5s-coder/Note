# add-tweaks.ps1
# Adds five new performance tweaks that are not already in the app.
# Each one is a documented Windows setting with a reversible original value.

$target = ".\config\tweaks.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "tweaks.json.addtweaks.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$site = "https://noteshopp.mysellauth.com"
$cat  = "Performance Tweaks"

$new = [ordered]@{}

# --- 1. Hardware-accelerated GPU scheduling -------------------------------
$new["WPFTweaksHAGS"] = [PSCustomObject]@{
    Content     = "GPU Scheduling (HAGS) - Enable"
    Description = "Lets the GPU manage its own command queue instead of the CPU doing it. MEASURABLE on RTX 30-series / RX 6000-series and newer with current drivers. Inconsistent on older cards. Reserves up to 1GB VRAM - if you have 8GB or less, test your 1% lows and turn it off if they get worse. Requires a reboot."
    category    = $cat
    panel       = "1"
    registry    = @(
        [PSCustomObject]@{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Name = "HwSchMode"; Value = "2"; Type = "DWord"; OriginalValue = "1"
        }
    )
    link = "$site"
}

# --- 2. Game DVR / background recording -----------------------------------
$new["WPFTweaksGameDVR"] = [PSCustomObject]@{
    Content     = "Background Game Recording - Disable"
    Description = "Xbox Game Bar records gameplay in the background continuously by default, costing CPU and disk activity even when you never use it. MEASURABLE - this is free performance if you do not use the recording feature."
    category    = $cat
    panel       = "1"
    registry    = @(
        [PSCustomObject]@{
            Path = "HKCU:\System\GameConfigStore"
            Name = "GameDVR_Enabled"; Value = "0"; Type = "DWord"; OriginalValue = "1"
        },
        [PSCustomObject]@{
            Path = "HKCU:\System\GameConfigStore"
            Name = "GameDVR_FSEBehaviorMode"; Value = "2"; Type = "DWord"; OriginalValue = "0"
        },
        [PSCustomObject]@{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
            Name = "AllowGameDVR"; Value = "0"; Type = "DWord"; OriginalValue = "<RemoveEntry>"
        }
    )
    link = "$site"
}

# --- 3. USB selective suspend ---------------------------------------------
$new["WPFTweaksUSBSuspend"] = [PSCustomObject]@{
    Content     = "USB Selective Suspend - Disable"
    Description = "Stops Windows putting USB devices to sleep to save power. SITUATIONAL - fixes mouse, keyboard and controller micro-disconnects and first-input delay. No benefit if you have never noticed those. Increases idle power draw slightly, so not ideal on a laptop running on battery."
    category    = $cat
    panel       = "1"
    registry    = @(
        [PSCustomObject]@{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
            Name = "DisableSelectiveSuspend"; Value = "1"; Type = "DWord"; OriginalValue = "<RemoveEntry>"
        }
    )
    link = "$site"
}

# --- 4. Multimedia scheduler (MMCSS) --------------------------------------
$new["WPFTweaksMMCSS"] = [PSCustomObject]@{
    Content     = "Multimedia Scheduler - Prioritise Foreground"
    Description = "By default Windows reserves 20 percent of CPU for background tasks and throttles network throughput while multimedia is playing. This releases both to the foreground app. SITUATIONAL - helps most on lower core-count CPUs and on machines with heavy background activity. Little effect on a modern high-core system that was never starved."
    category    = $cat
    panel       = "1"
    registry    = @(
        [PSCustomObject]@{
            Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            Name = "SystemResponsiveness"; Value = "0"; Type = "DWord"; OriginalValue = "20"
        },
        [PSCustomObject]@{
            Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            Name = "NetworkThrottlingIndex"; Value = "4294967295"; Type = "DWord"; OriginalValue = "10"
        }
    )
    link = "$site"
}

# --- 5. Scheduler quantum --------------------------------------------------
$new["WPFTweaksPriority"] = [PSCustomObject]@{
    Content     = "CPU Scheduler - Favour Foreground"
    Description = "Changes how the scheduler divides CPU time between the window you are using and everything else, using short variable time slices with a 3:1 bias to the foreground. SITUATIONAL - can improve responsiveness under load, but may slow background work such as encoding or compiling. Revert if you run long background jobs."
    category    = $cat
    panel       = "1"
    registry    = @(
        [PSCustomObject]@{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
            Name = "Win32PrioritySeparation"; Value = "38"; Type = "DWord"; OriginalValue = "2"
        }
    )
    link = "$site"
}

# --- apply -----------------------------------------------------------------
$added = 0
$skipped = 0

foreach ($key in $new.Keys) {
    if ($json.PSObject.Properties.Name -contains $key) {
        Write-Host "  skip (already exists): $key" -ForegroundColor Yellow
        $skipped++
    } else {
        $json | Add-Member -NotePropertyName $key -NotePropertyValue $new[$key]
        Write-Host "  added: $($new[$key].Content)" -ForegroundColor Green
        $added++
    }
}

$json | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $target -Encoding UTF8

Write-Host ""
Write-Host "DONE - $added added, $skipped skipped." -ForegroundColor Green
Write-Host ""
Write-Host "All five are reversible - each stores its original value," -ForegroundColor Cyan
Write-Host "so unticking the box puts Windows back the way it was." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host "Look for a new 'Performance Tweaks' category on the Tweaks tab." -ForegroundColor White
Write-Host ""
Write-Host "TEST IN A VM FIRST if you can. These change real system settings." -ForegroundColor Yellow
Write-Host ""
