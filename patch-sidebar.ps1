# patch-sidebar.ps1
# Converts the horizontal tab bar into a left sidebar.
# This edits XAML - if it goes wrong the app will not launch.
# Backup is made first; restore instructions printed at the end.

$target = ".\xaml\inputXML.xaml"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$backupFile = Join-Path $backupDir "inputXML.xaml.sidebar.backup"
Copy-Item $target $backupFile -Force
Write-Host "Backup: $backupFile" -ForegroundColor Green
Write-Host ""

$text = Get-Content -LiteralPath $target -Raw

# Normalise line endings so multi-line matches work regardless of CRLF/LF.
$hadCRLF = $text.Contains("`r`n")
$text = $text -replace "`r`n", "`n"

function Do-Replace {
    param([string]$Name, [string]$Find, [string]$New)
    if (-not $script:text.Contains($Find)) {
        Write-Host "  FAILED: $Name" -ForegroundColor Red
        Write-Host "  Could not find the expected markup. Aborting - no changes written." -ForegroundColor Red
        exit 1
    }
    $script:text = $script:text.Replace($Find, $New)
    Write-Host "  ok: $Name" -ForegroundColor Green
}

# ---- 1. main grid gets a sidebar column ----
$findCols = @'
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
'@
$newCols = @'
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
'@
Do-Replace "main grid columns" $findCols $newCols

# ---- 2. remove the horizontal nav panel ----
$findNav = '            <StackPanel Name="NavDockPanel" Orientation="Horizontal" Grid.Column="0" VerticalAlignment="Center" Margin="5,5,10,5">'
$idxStart = $text.IndexOf($findNav)
if ($idxStart -lt 0) {
    Write-Host "  FAILED: could not find NavDockPanel" -ForegroundColor Red
    exit 1
}
$marker = '            <!-- Search Bar and Action Buttons -->'
$idxEnd = $text.IndexOf($marker, $idxStart)
if ($idxEnd -lt 0) {
    Write-Host "  FAILED: could not find end of nav panel" -ForegroundColor Red
    exit 1
}
$text = $text.Substring(0, $idxStart) + $text.Substring($idxEnd)
Write-Host "  ok: removed horizontal nav panel" -ForegroundColor Green

# ---- 3. top bar moves to column 1 ----
Do-Replace "top bar column" `
    '        <Grid Grid.Row="1" Background="{DynamicResource MainBackgroundColor}">' `
    '        <Grid Grid.Row="1" Grid.Column="1" Background="{DynamicResource MainBackgroundColor}">'

# ---- 4. tab content moves to column 1 ----
Do-Replace "tab control column" `
    'Grid.Row="2" Grid.Column="0" Padding="-1"' `
    'Grid.Row="2" Grid.Column="1" Padding="-1"'

# ---- 5. offline banner spans both columns ----
Do-Replace "offline banner span" `
    '<Border Name="WPFOfflineBanner" Grid.Row="0"' `
    '<Border Name="WPFOfflineBanner" Grid.Row="0" Grid.ColumnSpan="2"'

# ---- 6. progress bar to column 1 ----
Do-Replace "progress bar column" `
    '<Border Name="WPFTweaksProgressBar" Grid.Row="3"' `
    '<Border Name="WPFTweaksProgressBar" Grid.Row="3" Grid.Column="1"'

# ---- 7. insert the sidebar ----
$sidebar = @'
        <Border Grid.Row="1" Grid.RowSpan="3" Grid.Column="0" Width="190"
                Background="{DynamicResource MainBackgroundColor}"
                BorderBrush="{DynamicResource BorderColor}" BorderThickness="0,0,1,0">
            <StackPanel Name="NavDockPanel" Orientation="Vertical" Margin="10,14,10,10">
                <StackPanel Name="NavLogoPanel" Orientation="Horizontal" HorizontalAlignment="Left" Margin="8,0,0,18" SnapsToDevicePixels="True">
                </StackPanel>
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,4" Height="36" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="12,0,0,0"
                    Background="{DynamicResource ButtonInstallBackgroundColor}" FontWeight="Bold" Name="WPFTab1BT">
                    <ToggleButton.Content>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="{DynamicResource ButtonInstallForegroundColor}" Text="&#xE896;"/>
                            <TextBlock FontSize="{DynamicResource TabButtonFontSize}" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource ButtonInstallForegroundColor}">
                                <Underline>I</Underline>nstall
                            </TextBlock>
                        </StackPanel>
                    </ToggleButton.Content>
                </ToggleButton>
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,4" Height="36" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="12,0,0,0"
                    Background="{DynamicResource ButtonTweaksBackgroundColor}" FontWeight="Bold" Name="WPFTab2BT">
                    <ToggleButton.Content>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="{DynamicResource ButtonTweaksForegroundColor}" Text="&#xE713;"/>
                            <TextBlock FontSize="{DynamicResource TabButtonFontSize}" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource ButtonTweaksForegroundColor}">
                                <Underline>T</Underline>weaks
                            </TextBlock>
                        </StackPanel>
                    </ToggleButton.Content>
                </ToggleButton>
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,4" Height="36" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="12,0,0,0"
                    Background="{DynamicResource ButtonConfigBackgroundColor}" FontWeight="Bold" Name="WPFTab3BT">
                    <ToggleButton.Content>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="{DynamicResource ButtonConfigForegroundColor}" Text="&#xE8B7;"/>
                            <TextBlock FontSize="{DynamicResource TabButtonFontSize}" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource ButtonConfigForegroundColor}">
                                <Underline>C</Underline>onfig
                            </TextBlock>
                        </StackPanel>
                    </ToggleButton.Content>
                </ToggleButton>
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,4" Height="36" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="12,0,0,0"
                    Background="{DynamicResource ButtonUpdatesBackgroundColor}" FontWeight="Bold" Name="WPFTab4BT">
                    <ToggleButton.Content>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="{DynamicResource ButtonUpdatesForegroundColor}" Text="&#xE895;"/>
                            <TextBlock FontSize="{DynamicResource TabButtonFontSize}" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource ButtonUpdatesForegroundColor}">
                                <Underline>U</Underline>pdates
                            </TextBlock>
                        </StackPanel>
                    </ToggleButton.Content>
                </ToggleButton>
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,4" Height="36" HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="12,0,0,0"
                    Background="{DynamicResource ButtonWin11ISOBackgroundColor}" FontWeight="Bold" Name="WPFTab5BT">
                    <ToggleButton.Content>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="15" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="{DynamicResource ButtonWin11ISOForegroundColor}" Text="&#xE8A5;"/>
                            <TextBlock FontSize="{DynamicResource TabButtonFontSize}" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource ButtonWin11ISOForegroundColor}">
                                <Underline>W</Underline>in11 Creator
                            </TextBlock>
                        </StackPanel>
                    </ToggleButton.Content>
                </ToggleButton>
            </StackPanel>
        </Border>

'@

$anchor = '        <Grid Grid.Row="1" Grid.Column="1" Background="{DynamicResource MainBackgroundColor}">'
Do-Replace "insert sidebar" $anchor ($sidebar + $anchor)

# Restore original line endings.
if ($hadCRLF) { $text = $text -replace "`n", "`r`n" }

Set-Content -LiteralPath $target -Value $text -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - sidebar applied." -ForegroundColor Green
Write-Host ""
Write-Host "Now run:  .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
Write-Host "IF THE APP DOES NOT OPEN, restore with:" -ForegroundColor Yellow
Write-Host "  Copy-Item '$backupFile' '$target' -Force" -ForegroundColor White
Write-Host "  .\Compile.ps1 -run" -ForegroundColor White
Write-Host ""
