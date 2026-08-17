#===========================================================================
# Tests - Tweak Orchestration
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Invoke-NoteTweaks.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFtweaksbutton.ps1")

    function Set-NoteService {
        param($Name, $StartupType)
    }
    function Set-NoteRegistry {
        param($Name, $Path, $Type, $Value)
    }
    function Invoke-NoteScript {
        param($Name, [scriptblock]$ScriptBlock)
    }
    function Remove-NoteAPPX {
        param($Name)
    }
    function Remove-NoteProvisionedAPPX {
        param($PackageList)
    }
    function Set-NoteDNS {
        param($DNSProvider)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock)
    }
    function Set-NoteTweaksProgressIndicator {
        param($Visible, $Label, $Percent)
    }
    function Write-NoteLog {
        param($Message, $Level, $Component)
    }

    function script:New-NoteTweaksConfig {
        [pscustomobject]@{
            WPFTweaksExample = [pscustomobject]@{
                service = @(
                    [pscustomobject]@{
                        Name = "DiagTrack"
                        StartupType = "Disabled"
                        OriginalType = "Automatic"
                    }
                )
                registry = @(
                    [pscustomobject]@{
                        Path = "HKLM:\Software\NoteTest"
                        Name = "AllowTelemetry"
                        Type = "DWord"
                        Value = "0"
                        OriginalValue = "1"
                    }
                )
                InvokeScript = @("Write-Output 'apply tweak'")
                UndoScript = @("Write-Output 'undo tweak'")
                appx = @("Microsoft.ExampleApp")
            }
            WPFTweaksServiceOnly = [pscustomobject]@{
                service = @(
                    [pscustomobject]@{
                        Name = "DiagTrack"
                        StartupType = "Disabled"
                        OriginalType = "Automatic"
                    }
                )
            }
        }
    }
}

Describe "Invoke-NoteTweaks" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                tweaks = New-NoteTweaksConfig
            }
        })

        Mock Get-Service {
            [pscustomobject]@{
                Name = "DiagTrack"
                StartType = "Automatic"
            }
        }
        Mock Set-NoteService { }
        Mock Set-NoteRegistry { }
        Mock Invoke-NoteScript { }
        Mock Remove-NoteAPPX { }
        Mock Remove-NoteProvisionedAPPX { }
        Mock Write-NoteLog { }
        Mock Write-Warning { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "dispatches apply actions to service, registry, script, and AppX helpers" {
        Invoke-NoteTweaks -CheckBox "WPFTweaksExample"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $ErrorAction -eq "Stop"
        }
        Should -Invoke -CommandName Set-NoteService -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $StartupType -eq "Disabled"
        }
        Should -Invoke -CommandName Set-NoteRegistry -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\Software\NoteTest" -and
                $Name -eq "AllowTelemetry" -and
                $Type -eq "DWord" -and
                $Value -eq "0"
        }
        Should -Invoke -CommandName Invoke-NoteScript -Times 1 -Exactly -ParameterFilter {
            $Name -eq "WPFTweaksExample" -and $ScriptBlock.ToString() -eq "Write-Output 'apply tweak'"
        }
        Should -Invoke -CommandName Remove-NoteAPPX -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Microsoft.ExampleApp"
        }
        Should -Invoke -CommandName Remove-NoteProvisionedAPPX -Times 1 -Exactly -ParameterFilter {
            $PackageList.Count -eq 1 -and $PackageList[0] -eq "Microsoft.ExampleApp"
        }
    }

    It "uses original registry values and service startup types in undo mode" {
        Invoke-NoteTweaks -CheckBox "WPFTweaksExample" -undo $true

        Should -Invoke -CommandName Get-Service -Times 0 -Exactly
        Should -Invoke -CommandName Set-NoteService -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $StartupType -eq "Automatic"
        }
        Should -Invoke -CommandName Set-NoteRegistry -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\Software\NoteTest" -and
                $Name -eq "AllowTelemetry" -and
                $Type -eq "DWord" -and
                $Value -eq "1"
        }
        Should -Invoke -CommandName Invoke-NoteScript -Times 1 -Exactly -ParameterFilter {
            $Name -eq "WPFTweaksExample" -and $ScriptBlock.ToString() -eq "Write-Output 'undo tweak'"
        }
        Should -Invoke -CommandName Remove-NoteAPPX -Times 0 -Exactly
        Should -Invoke -CommandName Remove-NoteProvisionedAPPX -Times 0 -Exactly
    }

    It "keeps a user-changed service startup type by default" {
        Mock Get-Service {
            [pscustomobject]@{
                Name = "DiagTrack"
                StartType = "Manual"
            }
        } -ParameterFilter { $Name -eq "DiagTrack" }

        Invoke-NoteTweaks -CheckBox "WPFTweaksServiceOnly"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly
        Should -Invoke -CommandName Set-NoteService -Times 0 -Exactly
    }

    It "forces a service startup type when KeepServiceStartup is disabled" {
        Invoke-NoteTweaks -CheckBox "WPFTweaksServiceOnly" -KeepServiceStartup $false

        Should -Invoke -CommandName Get-Service -Times 0 -Exactly
        Should -Invoke -CommandName Set-NoteService -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $StartupType -eq "Disabled"
        }
    }

}

Describe "Invoke-WPFtweaksbutton" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            WPFchangedns = [pscustomobject]@{
                text = "Cloudflare"
            }
        })
        $script:capturedTweaksScriptBlock = $null

        Mock Invoke-WPFRunspace {
            $script:capturedTweaksScriptBlock = $ScriptBlock
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Invoke-NoteTweaks { }
        Mock Set-NoteTweaksProgressIndicator { }
        Mock Invoke-WPFUIThread { }
        Mock Write-NoteLog { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedTweaksScriptBlock -Scope Script -ErrorAction SilentlyContinue
    }

    It "passes selected tweaks, DNS provider, and progress counters to the tweak runspace" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedTweaks.Add("WPFTweaksServices")

        Invoke-WPFtweaksbutton

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ParameterList.Count -eq 4 -and
                $ParameterList[0][0] -eq "tweaks" -and
                $ParameterList[0][1].Count -eq 2 -and
                $ParameterList[0][1][0] -eq "WPFTweaksTelemetry" -and
                $ParameterList[0][1][1] -eq "WPFTweaksServices" -and
                $ParameterList[1][0] -eq "dnsProvider" -and
                $ParameterList[1][1] -eq "Cloudflare" -and
                $ParameterList[2][0] -eq "completedSteps" -and
                $ParameterList[2][1] -eq 0 -and
                $ParameterList[3][0] -eq "totalSteps" -and
                $ParameterList[3][1] -eq 2
        }
    }

    It "runs the restore point first and advances progress before queueing remaining tweaks" {
        $script:sync.selectedTweaks.Add("WPFTweaksRestorePoint")
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")

        Invoke-WPFtweaksbutton

        Should -Invoke -CommandName Invoke-NoteTweaks -Times 1 -Exactly -ParameterFilter {
            $CheckBox -eq "WPFTweaksRestorePoint"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ParameterList.Count -eq 4 -and
                $ParameterList[0][0] -eq "tweaks" -and
                $ParameterList[0][1].Count -eq 1 -and
                $ParameterList[0][1][0] -eq "WPFTweaksTelemetry" -and
                $ParameterList[1][0] -eq "dnsProvider" -and
                $ParameterList[1][1] -eq "Cloudflare" -and
                $ParameterList[2][0] -eq "completedSteps" -and
                $ParameterList[2][1] -eq 1 -and
                $ParameterList[3][0] -eq "totalSteps" -and
                $ParameterList[3][1] -eq 2
        }
    }

    It "stops the tweak workflow when the DNS change fails" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        Mock Set-NoteDNS { return $false }

        Invoke-WPFtweaksbutton
        & $script:capturedTweaksScriptBlock -tweaks @("WPFTweaksTelemetry") -dnsProvider "Mullvad" -completedSteps 0 -totalSteps 1

        Should -Invoke -CommandName Invoke-NoteTweaks -Times 0 -Exactly
        Should -Invoke -CommandName Set-NoteTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "DNS change failed" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-NoteTaskbaritem -state "Error" -overlay "warning"*'
        }
        Should -Invoke -CommandName Write-NoteLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "Tweaks" -and
                $Message -eq "Tweaks workflow stopped because the DNS change failed."
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }
}
