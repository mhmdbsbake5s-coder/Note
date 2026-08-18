# patch-theme-green.ps1
# Applies a black and green palette.
# Change the colours below if you want a different green.

$Accent      = "#00E676"   # main green
$AccentHover = "#5CFFA8"   # brighter green for hover
$AccentDim   = "#00A855"   # darker green for less important accents

$BgDeep      = "#0A0A0A"   # window background
$BgPanel     = "#141414"   # cards and panels
$BgRaised    = "#1E1E1E"   # buttons, hovered rows
$BorderCol   = "#282828"
$TextMain    = "#EAEAEA"
$TextDim     = "#9A9A9A"

$target = ".\config\themes.json"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $target (Join-Path $backupDir "themes.json.green.backup") -Force
Write-Host "Backup saved to $backupDir" -ForegroundColor Green

$json = Get-Content -LiteralPath $target -Raw | ConvertFrom-Json

$palette = @{
    # surfaces
    "MainBackgroundColor"            = $BgDeep
    "LabelBackgroundColor"           = $BgDeep
    "ComboBoxBackgroundColor"        = $BgPanel
    "AppInstallUnselectedColor"      = $BgPanel
    "AppInstallHighlightedColor"     = $BgRaised
    "AppInstallSelectedColor"        = $AccentDim
    "ButtonBackgroundColor"          = $BgRaised
    "ButtonBackgroundSelectedColor"  = $AccentDim
    "ButtonBackgroundMouseoverColor" = "#2A2A2A"
    "ButtonBackgroundPressedColor"   = $Accent
    "GroupBorderBackgroundColor"     = $BgPanel
    "BorderColor"                    = $BorderCol
    "ToolTipBackgroundColor"         = $BgPanel

    # text
    "MainForegroundColor"            = $TextMain
    "LabelboxForegroundColor"        = $TextMain
    "ComboBoxForegroundColor"        = $TextMain
    "ButtonForegroundColor"          = $TextMain
    "ToolTipForegroundColor"         = $TextMain

    # tab buttons
    "ButtonInstallBackgroundColor"   = "Transparent"
    "ButtonTweaksBackgroundColor"    = "Transparent"
    "ButtonConfigBackgroundColor"    = "Transparent"
    "ButtonUpdatesBackgroundColor"   = "Transparent"
    "ButtonWin11ISOBackgroundColor"  = "Transparent"
    "ButtonAppxBackgroundColor"      = "Transparent"
    "ButtonInstallForegroundColor"   = $TextMain
    "ButtonTweaksForegroundColor"    = $TextMain
    "ButtonConfigForegroundColor"    = $TextMain
    "ButtonUpdatesForegroundColor"   = $TextMain
    "ButtonWin11ISOForegroundColor"  = $TextMain
    "ButtonAppxForegroundColor"      = $TextMain

    # accents - this is where the green shows
    "ToggleButtonOnColor"            = $Accent
    "ToggleButtonOffColor"           = "#3A3A3A"
    "ProgressBarForegroundColor"     = $Accent
    "ProgressBarBackgroundColor"     = "Transparent"
    "LinkForegroundColor"            = $Accent
    "LinkHoverForegroundColor"       = $AccentHover
    "CheckboxMouseOverColor"         = $Accent

    # scrollbars
    "ScrollBarBackgroundColor"       = "#2A2A2A"
    "ScrollBarHoverColor"            = "#3A3A3A"
    "ScrollBarDraggingColor"         = $AccentDim
}

$sections = @("Light","Dark")
$total = 0

foreach ($section in $sections) {
    if (-not ($json.PSObject.Properties.Name -contains $section)) { continue }
    $count = 0
    foreach ($key in $palette.Keys) {
        if ($json.$section.PSObject.Properties.Name -contains $key) {
            $json.$section.$key = $palette[$key]
            $count++
        } else {
            $json.$section | Add-Member -NotePropertyName $key -NotePropertyValue $palette[$key] -Force
            $count++
        }
    }
    Write-Host "  $section theme: $count values set" -ForegroundColor Green
    $total += $count
}

# a couple live in the shared block
foreach ($key in @("GroupBorderBackgroundColor","CheckboxMouseOverColor")) {
    if ($json.shared.PSObject.Properties.Name -contains $key) {
        $json.shared.$key = $palette[$key]
        Write-Host "  shared: $key" -ForegroundColor Green
    }
}

$json | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $target -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - black and green applied ($total values)." -ForegroundColor Green
Write-Host ""
Write-Host "Both Light and Dark are now dark, so the look stays" -ForegroundColor Cyan
Write-Host "consistent whichever theme mode is selected." -ForegroundColor Cyan
Write-Host ""
Write-Host "Want a different green? Open this file in Notepad, change" -ForegroundColor Yellow
Write-Host "the `$Accent value at the top, save, and run it again." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
