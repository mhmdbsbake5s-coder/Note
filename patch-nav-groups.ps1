# patch-nav-groups.ps1
# Restructures the sidebar into grouped sections with headers.
# Button labels change; internal tab names stay the same so nothing breaks.

$target = ".\xaml\inputXML.xaml"

if (-not (Test-Path $target)) {
    Write-Host "ERROR: Could not find $target" -ForegroundColor Red
    exit 1
}

$backupDir = ".\_backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$backupFile = Join-Path $backupDir "inputXML.xaml.navgroups.backup"
Copy-Item $target $backupFile -Force
Write-Host "Backup: $backupFile" -ForegroundColor Green

$text = Get-Content -LiteralPath $target -Raw
$hadCRLF = $text.Contains("`r`n")
$text = $text -replace "`r`n", "`n"

$startMarker = '        <Border Grid.Row="1" Grid.RowSpan="3" Grid.Column="0" Width="230"'
$endMarker   = '        <Grid Grid.Row="1" Grid.Column="1" Background="{DynamicResource MainBackgroundColor}">'

$i1 = $text.IndexOf($startMarker)
$i2 = $text.IndexOf($endMarker)

if ($i1 -lt 0 -or $i2 -lt 0 -or $i2 -le $i1) {
    Write-Host ""
    Write-Host "ERROR: Could not locate the sidebar block. Nothing changed." -ForegroundColor Red
    exit 1
}

function New-NavHeader {
    param([string]$Text)
    return @"
                <TextBlock Text="$Text" Foreground="#00E676" FontFamily="Cascadia Mono, Consolas"
                           FontSize="10" Margin="18,20,0,8"/>

"@
}

function New-NavButton {
    param([string]$Name, [string]$Accel, [string]$Rest)
    return @"
                <ToggleButton Style="{StaticResource TabToggleButton}" Margin="0,0,0,3" Height="40"
                    HorizontalAlignment="Stretch" HorizontalContentAlignment="Left" Padding="18,0,0,0"
                    BorderThickness="0" BorderBrush="Transparent"
                    Background="Transparent" FontWeight="Normal" Name="$Name">
                    <ToggleButton.Content>
                        <TextBlock FontSize="14" VerticalAlignment="Center" Background="Transparent" Foreground="{DynamicResource MainForegroundColor}">
                            <Underline>$Accel</Underline>$Rest
                        </TextBlock>
                    </ToggleButton.Content>
                </ToggleButton>

"@
}

$body  = New-NavButton "WPFTab7BT" "H" "ome"
$body += New-NavHeader "SET UP"
$body += New-NavButton "WPFTab1BT" "A" "pps"
$body += New-NavButton "WPFTab5BT" "W" "indows Image"
$body += New-NavHeader "OPTIMISE"
$body += New-NavButton "WPFTab2BT" "T" "uning"
$body += New-NavHeader "MAINTAIN"
$body += New-NavButton "WPFTab3BT" "T" "ools"
$body += New-NavButton "WPFTab4BT" "U" "pdates"

$newSidebar = @"
        <Border Grid.Row="1" Grid.RowSpan="3" Grid.Column="0" Width="230"
                Background="{DynamicResource MainBackgroundColor}"
                BorderBrush="{DynamicResource BorderColor}" BorderThickness="0,0,1,0">
            <StackPanel Name="NavDockPanel" Orientation="Vertical" Margin="14,20,14,16">
                <StackPanel Name="NavLogoPanel" Orientation="Horizontal" HorizontalAlignment="Left" Margin="6,0,0,22" SnapsToDevicePixels="True">
                </StackPanel>
$body            </StackPanel>
        </Border>

"@

$text = $text.Substring(0, $i1) + $newSidebar + $text.Substring($i2)

if ($hadCRLF) { $text = $text -replace "`n", "`r`n" }
Set-Content -LiteralPath $target -Value $text -NoNewline -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS - navigation restructured." -ForegroundColor Green
Write-Host ""
Write-Host "  Home" -ForegroundColor White
Write-Host "  SET UP     - Apps, Windows Image" -ForegroundColor White
Write-Host "  OPTIMISE   - Tuning" -ForegroundColor White
Write-Host "  MAINTAIN   - Tools, Updates" -ForegroundColor White
Write-Host ""
Write-Host "Next: .\Compile.ps1 -run" -ForegroundColor Cyan
Write-Host ""
Write-Host "If it breaks, restore with:" -ForegroundColor Yellow
Write-Host "  Copy-Item '$backupFile' '$target' -Force" -ForegroundColor White
Write-Host ""
