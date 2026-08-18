# add-home-tab.ps1
# Adds a Home dashboard as tab 7, with its button first in the sidebar.

$xamlPath = ".\xaml\inputXML.xaml"
$tabPath  = ".\functions\public\Invoke-WPFTab.ps1"
$funcPath = ".\functions\public\Invoke-WPFHomeDashboard.ps1"

foreach ($p in @($xamlPath, $tabPath)) {
    if (-not (Test-Path $p)) {
        Write-Host "ERROR: Could not find $p" -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $funcPath)) {
    Write-Host ""
    Write-Host "ERROR: $funcPath is missing." -ForegroundColor Red
    Write-Host "Put Invoke-WPFHomeDashboard.ps1 in functions\public first." -ForegroundColor Red
    exit 1
}
Write-Host "Found the dashboard function." -ForegroundColor Green

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
Copy-Item $xamlPath (Join-Path $backupDir "inputXML.xaml.home.backup") -Force
Copy-Item $tabPath  (Join-Path $backupDir "Invoke-WPFTab.ps1.home.backup") -Force
Write-Host "Backups saved to $backupDir" -ForegroundColor Green
Write-Host ""

# ---------------- 1. XAML: add the TabItem ----------------
$xaml = Get-Content -LiteralPath $xamlPath -Raw
$hadCRLF = $xaml.Contains("`r`n")
$xaml = $xaml -replace "`r`n", "`n"

if ($xaml.Contains('Name="WPFTab7"')) {
    Write-Host "  Home tab already present - skipping XAML changes." -ForegroundColor Yellow
} else {
    $closeTag = "        </TabControl>"
    if (-not $xaml.Contains($closeTag)) {
        Write-Host "  FAILED: could not find end of TabControl" -ForegroundColor Red
        exit 1
    }

    $tabItem = @'
            <TabItem Header="Home" Visibility="Collapsed" Name="WPFTab7">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="0">
                    <StackPanel Margin="24,20,24,24">
                        <TextBlock Text="Note" Foreground="#EAEAEA" FontSize="26" FontFamily="Cascadia Mono, Consolas"/>
                        <TextBlock Text="Windows toolbox" Foreground="#9A9A9A" FontSize="13" Margin="0,4,0,0"/>
                        <StackPanel Name="HomePanel" Margin="0,6,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

'@
    $xaml = $xaml.Replace($closeTag, $tabItem + $closeTag)
    Write-Host "  ok: added Home TabItem (index 7)" -ForegroundColor Green

    # ---------------- 2. XAML: sidebar button, placed first ----------------
    $anchor = '                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,16" Height="44'
    $idx = $xaml.IndexOf($anchor)
    if ($idx -lt 0) {
        Write-Host "  FAILED: could not find the first sidebar button" -ForegroundColor Red
        Write-Host "  Did patch-sidebar-spacing.ps1 run? Aborting." -ForegroundColor Red
        exit 1
    }

    $homeBtn = @'
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,16" Height="44"
                    HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="16,0,0,0"
                    BorderThickness="0" BorderBrush="Transparent"
                    Background="Transparent" FontWeight="Normal" Name="WPFTab7BT">
                    <ToggleButton.Content>
                        <TextBlock FontSize="14" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource MainForegroundColor}">
                            <Underline>H</Underline>ome
                        </TextBlock>
                    </ToggleButton.Content>
                </ToggleButton>

'@
    $xaml = $xaml.Substring(0, $idx) + $homeBtn + $xaml.Substring($idx)
    Write-Host "  ok: added Home button at top of sidebar" -ForegroundColor Green
}

if ($hadCRLF) { $xaml = $xaml -replace "`n", "`r`n" }
Set-Content -LiteralPath $xamlPath -Value $xaml -NoNewline -Encoding UTF8

# ---------------- 3. hook the dashboard into tab switching ----------------
$tabCode = Get-Content -LiteralPath $tabPath -Raw

if ($tabCode.Contains("Invoke-WPFHomeDashboard")) {
    Write-Host "  dashboard hook already present - skipping." -ForegroundColor Yellow
} else {
    $find = '    Initialize-NoteTabContent -TabName $sync.currentTab'
    if (-not $tabCode.Contains($find)) {
        Write-Host "  FAILED: could not find the tab content call" -ForegroundColor Red
        exit 1
    }
    $replace = @'
    if ($sync.currentTab -eq "Home") {
        Invoke-WPFHomeDashboard
    } else {
        Initialize-NoteTabContent -TabName $sync.currentTab
    }
'@
    $tabCode = $tabCode.Replace($find, $replace)
    Set-Content -LiteralPath $tabPath -Value $tabCode -NoNewline -Encoding UTF8
    Write-Host "  ok: hooked dashboard into tab switching" -ForegroundColor Green
}

Write-Host ""
Write-Host "SUCCESS - Home dashboard added." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run   then click Home in the sidebar." -ForegroundColor Cyan
Write-Host ""
Write-Host "If the app will not open, restore with:" -ForegroundColor Yellow
Write-Host "  Copy-Item '$backupDir\inputXML.xaml.home.backup' '$xamlPath' -Force" -ForegroundColor White
Write-Host "  Copy-Item '$backupDir\Invoke-WPFTab.ps1.home.backup' '$tabPath' -Force" -ForegroundColor White
Write-Host ""
