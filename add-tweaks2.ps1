# add-tweaks2.ps1
# Batch two: tweaks that need script blocks, not just registry values.

$target = ".\config\tweaks.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "tweaks.json.addtweaks2.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$site = "https://noteshopp.mysellauth.com"
$cat  = "Performance Tweaks"

$new = [ordered]@{}

# --- 1. Nagle's algorithm --------------------------------------------------
$nagleOn = 'Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }'
$nagleOff = 'Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object { Remove-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Force -ErrorAction SilentlyContinue; Remove-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Force -ErrorAction SilentlyContinue }'

$new["WPFTweaksNagle"] = [PSCustomObject]@{
    Content     = "Nagle's Algorithm - Disable"
    Description = "Windows batches small network packets together before sending, which adds a few milliseconds of delay. Disabling sends them immediately. SITUATIONAL - the classic latency tweak, and it genuinely helps some connections while doing nothing at all on others. Costs slightly more bandwidth overhead. Applies to all network adapters."
    category    = $cat
    panel       = "1"
    InvokeScript = @($nagleOn)
    UndoScript   = @($nagleOff)
    link = "$site"
}

# --- 2. PCIe link state power management -----------------------------------
$aspmOff = 'powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0; powercfg /setactive SCHEME_CURRENT'
$aspmOn  = 'powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1; powercfg /setactive SCHEME_CURRENT'

$new["WPFTweaksPCIeASPM"] = [PSCustomObject]@{
    Content     = "PCIe Power Saving - Disable"
    Description = "Stops the PCIe bus dropping into low-power states, which can add wake-up latency for your GPU and NVMe drive. SITUATIONAL - helps with occasional micro-stutter on desktops. Increases idle power draw, so do not use this on a laptop running on battery. Undo restores moderate power saving, not necessarily your exact original setting."
    category    = $cat
    panel       = "1"
    InvokeScript = @($aspmOff)
    UndoScript   = @($aspmOn)
    link = "$site"
}

# --- 3. Memory compression -------------------------------------------------
$new["WPFTweaksMemComp"] = [PSCustomObject]@{
    Content     = "Memory Compression - Disable"
    Description = "Windows compresses RAM pages to fit more in memory, trading CPU time for RAM. SITUATIONAL and depends entirely on your hardware. If you have 32GB or more, disabling saves CPU cycles you do not need to spend. If you have 8GB or 16GB, LEAVE THIS ALONE - disabling it will push you into paging to disk and make things markedly worse."
    category    = $cat
    panel       = "1"
    InvokeScript = @('Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue')
    UndoScript   = @('Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue')
    link = "$site"
}

# --- 4. Power throttling ---------------------------------------------------
$new["WPFTweaksPowerThrottle"] = [PSCustomObject]@{
    Content     = "CPU Power Throttling - Disable"
    Description = "Windows throttles apps it decides are running in the background to save power. It sometimes misjudges which app is which, throttling something you are actively waiting on. MEASURABLE on laptops and efficiency-core CPUs. Increases power draw and heat, so it is a desktop or plugged-in tweak."
    category    = $cat
    panel       = "1"
    registry    = @(
        [PSCustomObject]@{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
            Name = "PowerThrottlingOff"; Value = "1"; Type = "DWord"; OriginalValue = "<RemoveEntry>"
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
Write-Host "Nine performance tweaks total now." -ForegroundColor Cyan
Write-Host ""
Write-Host "TEST IN A VM. The memory compression one in particular can" -ForegroundColor Yellow
Write-Host "make a low-RAM machine noticeably worse." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
