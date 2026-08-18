function Invoke-WPFStartupManager {
    <#
    .SYNOPSIS
        Lists programs that launch at startup and lets the user enable or disable them.
    .DESCRIPTION
        Reads the Run keys and Startup folders, then toggles entries using Windows'
        own StartupApproved mechanism - the same one Task Manager uses. Nothing is
        deleted, so every change is reversible.
    #>

    $runKeys = @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Scope = "User";   Approved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" }
        @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Scope = "System"; Approved = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" }
        @{ Path = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Scope = "System (32-bit)"; Approved = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" }
    )

    $folderApproved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
    $startupFolders = @(
        @{ Path = [Environment]::GetFolderPath("Startup");       Scope = "User folder" }
        @{ Path = [Environment]::GetFolderPath("CommonStartup"); Scope = "All users folder" }
    )

    function Get-ApprovalState {
        param($ApprovedPath, $Name)
        try {
            $val = Get-ItemProperty -Path $ApprovedPath -Name $Name -ErrorAction Stop
            $bytes = $val.$Name
            if ($bytes -is [byte[]] -and $bytes.Length -gt 0) {
                # even first byte = enabled, odd = disabled
                return (($bytes[0] % 2) -eq 0)
            }
        } catch { }
        return $true
    }

    $entries = New-Object System.Collections.Generic.List[PSObject]

    foreach ($key in $runKeys) {
        if (-not (Test-Path $key.Path)) { continue }
        $props = Get-ItemProperty -Path $key.Path -ErrorAction SilentlyContinue
        if (-not $props) { continue }
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -like "PS*") { continue }
            $entries.Add([PSCustomObject]@{
                Name         = $p.Name
                Command      = [string]$p.Value
                Scope        = $key.Scope
                ApprovedPath = $key.Approved
                Kind         = "Registry"
                FilePath     = $null
                Enabled      = (Get-ApprovalState $key.Approved $p.Name)
            })
        }
    }

    foreach ($folder in $startupFolders) {
        if ([string]::IsNullOrWhiteSpace($folder.Path)) { continue }
        if (-not (Test-Path $folder.Path)) { continue }
        Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.lnk','.url','.bat','.cmd','.exe' } |
            ForEach-Object {
                $entries.Add([PSCustomObject]@{
                    Name         = $_.BaseName
                    Command      = $_.FullName
                    Scope        = $folder.Scope
                    ApprovedPath = $folderApproved
                    Kind         = "Folder"
                    FilePath     = $_.Name
                    Enabled      = (Get-ApprovalState $folderApproved $_.Name)
                })
            }
    }

    if ($entries.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No startup programs found.", "Startup Manager", "OK", "Info")
        return
    }

    $sorted = $entries | Sort-Object -Property @{Expression={-not $_.Enabled}}, Name

    # ---------- window ----------
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Startup Manager" Height="560" Width="720"
        WindowStartupLocation="CenterScreen" Background="#1A1A1A">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,14">
            <TextBlock Text="Startup programs" Foreground="#FFFFFF" FontSize="19" FontWeight="SemiBold"/>
            <TextBlock Name="SubText" Foreground="#9A9A9A" FontSize="12" Margin="0,5,0,0" TextWrapping="Wrap"/>
        </StackPanel>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="ItemList"/>
        </ScrollViewer>
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
            <TextBlock Name="StatusText" Foreground="#9A9A9A" FontSize="12" VerticalAlignment="Center" Margin="0,0,14,0"/>
            <Button Name="CloseBtn" Content="Close" Width="100" Height="32" Background="#2C2C2C" Foreground="#FFFFFF" BorderThickness="0"/>
        </StackPanel>
    </Grid>
</Window>
"@

    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $itemList   = $window.FindName("ItemList")
    $statusText = $window.FindName("StatusText")
    $subText    = $window.FindName("SubText")
    $closeBtn   = $window.FindName("CloseBtn")

    $enabledCount = ($sorted | Where-Object { $_.Enabled }).Count
    $subText.Text = "$($sorted.Count) programs set to run at startup, $enabledCount currently enabled. Disabling does not uninstall anything - untick to stop it launching, tick to allow it again."

    foreach ($entry in $sorted) {

        $border = New-Object Windows.Controls.Border
        $border.Background = "#242424"
        $border.CornerRadius = 8
        $border.Padding = "12,10"
        $border.Margin = "0,0,0,7"

        $grid = New-Object Windows.Controls.Grid
        $c1 = New-Object Windows.Controls.ColumnDefinition
        $c1.Width = "*"
        $c2 = New-Object Windows.Controls.ColumnDefinition
        $c2.Width = "Auto"
        $grid.ColumnDefinitions.Add($c1)
        $grid.ColumnDefinitions.Add($c2)

        $info = New-Object Windows.Controls.StackPanel

        $nameBlock = New-Object Windows.Controls.TextBlock
        $nameBlock.Text = $entry.Name
        $nameBlock.Foreground = "#F0F0F0"
        $nameBlock.FontSize = 14

        $metaBlock = New-Object Windows.Controls.TextBlock
        $cmd = $entry.Command
        if ($cmd.Length -gt 78) { $cmd = $cmd.Substring(0,78) + "..." }
        $metaBlock.Text = "$($entry.Scope)  -  $cmd"
        $metaBlock.Foreground = "#8A8A8A"
        $metaBlock.FontSize = 11
        $metaBlock.Margin = "0,3,0,0"
        $metaBlock.TextTrimming = "CharacterEllipsis"

        [void]$info.Children.Add($nameBlock)
        [void]$info.Children.Add($metaBlock)
        [Windows.Controls.Grid]::SetColumn($info, 0)
        [void]$grid.Children.Add($info)

        $check = New-Object Windows.Controls.CheckBox
        $check.IsChecked = $entry.Enabled
        $check.VerticalAlignment = "Center"
        $check.Margin = "12,0,2,0"
        $check.Tag = $entry
        [Windows.Controls.Grid]::SetColumn($check, 1)
        [void]$grid.Children.Add($check)

        $handler = {
            $box = $args[0]
            $item = $box.Tag
            $enable = [bool]$box.IsChecked

            $valueName = if ($item.Kind -eq "Folder") { $item.FilePath } else { $item.Name }

            try {
                if (-not (Test-Path $item.ApprovedPath)) {
                    New-Item -Path $item.ApprovedPath -Force | Out-Null
                }
                # first byte 2 = enabled, 3 = disabled; remaining bytes are a timestamp
                $bytes = if ($enable) {
                    [byte[]](2,0,0,0,0,0,0,0,0,0,0,0)
                } else {
                    [byte[]](3,0,0,0,0,0,0,0,0,0,0,0)
                }
                Set-ItemProperty -Path $item.ApprovedPath -Name $valueName -Value $bytes -Type Binary -Force -ErrorAction Stop
                $statusText.Text = if ($enable) { "Enabled $($item.Name)" } else { "Disabled $($item.Name)" }
            } catch {
                $statusText.Text = "Could not change $($item.Name) - try running as administrator"
                $box.IsChecked = -not $enable
            }
        }

        $check.Add_Checked($handler)
        $check.Add_Unchecked($handler)

        $border.Child = $grid
        [void]$itemList.Children.Add($border)
    }

    $closeBtn.Add_Click({ $window.Close() })

    [void]$window.ShowDialog()
}
