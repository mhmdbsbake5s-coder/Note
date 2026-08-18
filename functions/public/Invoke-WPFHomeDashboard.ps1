function Invoke-WPFHomeDashboard {
    <#
    .SYNOPSIS
        Fills the Home dashboard with live system information.
    .DESCRIPTION
        Called when the Home tab is opened. Reads OS, CPU, memory, GPU and
        disk details and renders them into the HomePanel container.
    #>

    $panel = $sync.Form.FindName("HomePanel")
    if (-not $panel) { return }

    $panel.Children.Clear()

    $accent  = "#00E676"
    $textMain = "#EAEAEA"
    $textDim  = "#9A9A9A"
    $cardBg   = "#141414"

    function New-SectionHeader {
        param([string]$Text)
        $tb = New-Object Windows.Controls.TextBlock
        $tb.Text = $Text.ToUpper()
        $tb.Foreground = $accent
        $tb.FontFamily = "Cascadia Mono, Consolas"
        $tb.FontSize = 12
        $tb.Margin = "2,18,0,8"
        return $tb
    }

    function New-InfoCard {
        param([string]$Label, [string]$Value)
        $border = New-Object Windows.Controls.Border
        $border.Background = $cardBg
        $border.CornerRadius = 8
        $border.Padding = "14,11"
        $border.Margin = "0,0,0,6"

        $sp = New-Object Windows.Controls.StackPanel

        $l = New-Object Windows.Controls.TextBlock
        $l.Text = $Label
        $l.Foreground = $textDim
        $l.FontSize = 11

        $v = New-Object Windows.Controls.TextBlock
        $v.Text = $Value
        $v.Foreground = $textMain
        $v.FontSize = 14
        $v.Margin = "0,3,0,0"
        $v.TextWrapping = "Wrap"

        [void]$sp.Children.Add($l)
        [void]$sp.Children.Add($v)
        $border.Child = $sp
        return $border
    }

    function New-DiskBar {
        param([string]$Name, [double]$UsedGB, [double]$TotalGB)

        $pct = if ($TotalGB -gt 0) { [math]::Round(($UsedGB / $TotalGB) * 100) } else { 0 }

        $border = New-Object Windows.Controls.Border
        $border.Background = $cardBg
        $border.CornerRadius = 8
        $border.Padding = "14,11"
        $border.Margin = "0,0,0,6"

        $sp = New-Object Windows.Controls.StackPanel

        $head = New-Object Windows.Controls.Grid
        $ca = New-Object Windows.Controls.ColumnDefinition; $ca.Width = "*"
        $cb = New-Object Windows.Controls.ColumnDefinition; $cb.Width = "Auto"
        $head.ColumnDefinitions.Add($ca); $head.ColumnDefinitions.Add($cb)

        $n = New-Object Windows.Controls.TextBlock
        $n.Text = $Name
        $n.Foreground = $textMain
        $n.FontSize = 13
        [Windows.Controls.Grid]::SetColumn($n, 0)

        $s = New-Object Windows.Controls.TextBlock
        $s.Text = "$([math]::Round($UsedGB)) / $([math]::Round($TotalGB)) GB  ($pct%)"
        $s.Foreground = $textDim
        $s.FontSize = 11
        $s.VerticalAlignment = "Center"
        [Windows.Controls.Grid]::SetColumn($s, 1)

        [void]$head.Children.Add($n)
        [void]$head.Children.Add($s)
        [void]$sp.Children.Add($head)

        $track = New-Object Windows.Controls.Border
        $track.Background = "#2A2A2A"
        $track.CornerRadius = 3
        $track.Height = 6
        $track.Margin = "0,9,0,0"
        $track.HorizontalAlignment = "Stretch"

        $fillGrid = New-Object Windows.Controls.Grid
        $fillGrid.HorizontalAlignment = "Stretch"

        $fill = New-Object Windows.Controls.Border
        $fill.CornerRadius = 3
        $fill.HorizontalAlignment = "Left"
        $fill.Height = 6
        # colour shifts as the disk fills up
        $fill.Background = if ($pct -ge 90) { "#FF5252" } elseif ($pct -ge 75) { "#FFB300" } else { $accent }

        $fill.Tag = $pct
        $track.SizeChanged += {
            param($s2, $e2)
            $inner = $s2.Child.Children[0]
            $inner.Width = [math]::Max(0, $e2.NewSize.Width * ($inner.Tag / 100))
        }

        [void]$fillGrid.Children.Add($fill)
        $track.Child = $fillGrid

        [void]$sp.Children.Add($track)
        $border.Child = $sp
        return $border
    }

    try {
        $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1

        [void]$panel.Children.Add((New-SectionHeader "System"))

        if ($os) {
            $build = "$($os.Caption) (build $($os.BuildNumber))"
            [void]$panel.Children.Add((New-InfoCard "Operating system" $build))

            $up = (Get-Date) - $os.LastBootUpTime
            $upText = "{0}d {1}h {2}m" -f $up.Days, $up.Hours, $up.Minutes
            [void]$panel.Children.Add((New-InfoCard "Uptime since last restart" $upText))
        }

        if ($cpu) {
            $cpuText = "$($cpu.Name.Trim())  -  $($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads"
            [void]$panel.Children.Add((New-InfoCard "Processor" $cpuText))
        }

        if ($os) {
            $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
            $usedGB  = [math]::Round($totalGB - $freeGB, 1)
            [void]$panel.Children.Add((New-InfoCard "Memory" "$usedGB GB used of $totalGB GB"))
        }

        if ($gpu) {
            [void]$panel.Children.Add((New-InfoCard "Graphics" $gpu.Name))
        }

        [void]$panel.Children.Add((New-SectionHeader "Storage"))

        Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue | ForEach-Object {
            $totalGB = [math]::Round($_.Size / 1GB, 1)
            $freeGB  = [math]::Round($_.FreeSpace / 1GB, 1)
            $usedGB  = [math]::Round($totalGB - $freeGB, 1)
            $label = if ([string]::IsNullOrWhiteSpace($_.VolumeName)) { $_.DeviceID } else { "$($_.DeviceID)  $($_.VolumeName)" }
            [void]$panel.Children.Add((New-DiskBar $label $usedGB $totalGB))
        }
    } catch {
        $err = New-Object Windows.Controls.TextBlock
        $err.Text = "Could not read system information: $($_.Exception.Message)"
        $err.Foreground = "#FF5252"
        $err.TextWrapping = "Wrap"
        [void]$panel.Children.Add($err)
    }
}
