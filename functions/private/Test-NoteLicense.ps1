function Test-NoteLicense {
    <#
    .SYNOPSIS
        Checks for a valid, unexpired licence key. Prompts for one if needed.
    .DESCRIPTION
        Keys are valid for 24 hours from first activation. Activation state is
        stored under HKCU. Includes basic clock-rollback detection.
        Returns $true if the app should run, $false if it should exit.
    .NOTES
        Offline validation is a deterrent, not real protection - the script can
        be extracted from the exe. Server-side validation is the only robust
        approach.
    #>

    Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

    $regPath   = "HKCU:\Software\Note\License"
    $salt      = "N0te-2026-Wx7"          # change this to invalidate all existing keys
    $hoursValid = 24

    # ---------- key validation ----------
    function Get-Checksum {
        param([string]$Body)
        $seed = "$Body$salt"
        $sum = 0
        for ($i = 0; $i -lt $seed.Length; $i++) {
            $sum += ([int][char]$seed[$i]) * ($i + 3)
        }
        $sum = $sum % 1679616   # 36^4
        $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        $out = ""
        for ($i = 0; $i -lt 4; $i++) {
            $out = $chars[$sum % 36] + $out
            $sum = [math]::Floor($sum / 36)
        }
        return $out
    }

    function Test-KeyFormat {
        param([string]$Key)
        $k = ($Key -replace '\s','').ToUpper()
        if ($k -notmatch '^NOTE-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') { return $false }
        $parts = $k.Split('-')
        $body = "$($parts[1])$($parts[2])"
        return ((Get-Checksum $body) -eq $parts[3])
    }

    # ---------- stored state ----------
    function Get-State {
        try {
            if (-not (Test-Path $regPath)) { return $null }
            return Get-ItemProperty -Path $regPath -ErrorAction Stop
        } catch { return $null }
    }

    function Save-State {
        param([string]$Key, [datetime]$Activated)
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "Key"       -Value $Key -Force
        Set-ItemProperty -Path $regPath -Name "Activated" -Value $Activated.ToString("o") -Force
        Set-ItemProperty -Path $regPath -Name "LastSeen"  -Value (Get-Date).ToString("o") -Force
    }

    function Add-UsedKey {
        param([string]$Key)
        $state = Get-State
        $used = @()
        if ($state -and $state.PSObject.Properties.Name -contains "Used") {
            $used = @($state.Used)
        }
        if ($used -notcontains $Key) { $used += $Key }
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "Used" -Value $used -Type MultiString -Force
    }

    function Test-KeyUsed {
        param([string]$Key)
        $state = Get-State
        if (-not $state) { return $false }
        if ($state.PSObject.Properties.Name -notcontains "Used") { return $false }
        return (@($state.Used) -contains $Key)
    }

    # ---------- is the current licence still good? ----------
    $state = Get-State
    $now = Get-Date

    if ($state -and $state.PSObject.Properties.Name -contains "Activated") {
        try {
            $activated = [datetime]::Parse($state.Activated)
            $lastSeen  = if ($state.PSObject.Properties.Name -contains "LastSeen") {
                [datetime]::Parse($state.LastSeen)
            } else { $activated }

            # clock rolled back - treat as expired
            if ($now -lt $lastSeen.AddMinutes(-5)) {
                Add-UsedKey $state.Key
            } else {
                $elapsed = $now - $activated
                if ($elapsed.TotalHours -lt $hoursValid) {
                    Set-ItemProperty -Path $regPath -Name "LastSeen" -Value $now.ToString("o") -Force
                    return $true
                } else {
                    Add-UsedKey $state.Key
                }
            }
        } catch { }
    }

    # ---------- prompt for a key ----------
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Note" Height="290" Width="430" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen" Background="#0A0A0A">
    <StackPanel Margin="28,24,28,24">
        <TextBlock Text="Note" Foreground="#EAEAEA" FontSize="26" FontFamily="Cascadia Mono, Consolas"/>
        <TextBlock Name="Msg" Foreground="#9A9A9A" FontSize="12" Margin="0,8,0,0" TextWrapping="Wrap"/>
        <TextBox Name="KeyBox" Margin="0,20,0,0" Height="34" FontSize="14"
                 Background="#141414" Foreground="#EAEAEA" BorderBrush="#282828"
                 BorderThickness="1" Padding="8,0,0,0" VerticalContentAlignment="Center"/>
        <TextBlock Name="ErrText" Foreground="#FF5252" FontSize="12" Margin="0,8,0,0" TextWrapping="Wrap"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <Button Name="QuitBtn" Content="Quit" Width="90" Height="32" Margin="0,0,8,0"
                    Background="#1E1E1E" Foreground="#EAEAEA" BorderThickness="0"/>
            <Button Name="OkBtn" Content="Activate" Width="110" Height="32"
                    Background="#00E676" Foreground="#0A0A0A" BorderThickness="0" FontWeight="Bold"/>
        </StackPanel>
    </StackPanel>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $win = [Windows.Markup.XamlReader]::Load($reader)

    $msg    = $win.FindName("Msg")
    $keyBox = $win.FindName("KeyBox")
    $errTxt = $win.FindName("ErrText")
    $okBtn  = $win.FindName("OkBtn")
    $quit   = $win.FindName("QuitBtn")

    $msg.Text = if ($state) {
        "Your access has expired. Enter a new key to continue. Each key is valid for 24 hours."
    } else {
        "Enter your key to activate. Access lasts 24 hours from activation."
    }

    $keyBox.Text = "NOTE-"
    $keyBox.CaretIndex = $keyBox.Text.Length

    $script:licenceOk = $false

    $okBtn.Add_Click({
        $entered = $keyBox.Text.Trim().ToUpper()

        if (-not (Test-KeyFormat $entered)) {
            $errTxt.Text = "That key is not valid. Check for typos and try again."
            return
        }
        if (Test-KeyUsed $entered) {
            $errTxt.Text = "That key has already been used and has expired."
            return
        }

        Save-State -Key $entered -Activated (Get-Date)
        $script:licenceOk = $true
        $win.Close()
    })

    $keyBox.Add_KeyDown({
        if ($_.Key -eq "Return") { $okBtn.RaiseEvent((New-Object Windows.RoutedEventArgs([Windows.Controls.Primitives.ButtonBase]::ClickEvent))) }
    })

    $quit.Add_Click({ $script:licenceOk = $false; $win.Close() })

    [void]$win.ShowDialog()

    return $script:licenceOk
}
