#===========================================================================
# Tests - O&O ShutUp10++ Download Workflow
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Save-NoteFile.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFOOSU.ps1")

    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Set-NoteTweaksProgressIndicator {
        param($Visible, $Label, $Percent)
    }
    function Show-NoteMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Write-NoteLog {
        param($Message, $Level, $Component)
    }

    function script:New-NoteOOSUTestContext {
        param([bool]$ProcessRunning = $false)

        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $ProcessRunning
            Notedir = $TestDrive
            Form = [pscustomobject]@{
                Dispatcher = [pscustomobject]@{}
            }
        })
    }
}

Describe "Save-NoteFile" {
    It "copies a download and reports its percentage" {
        $sourcePath = Join-Path $TestDrive "source.bin"
        $destinationPath = Join-Path $TestDrive "destination.bin"
        $sourceBytes = [byte[]](0..255)
        [System.IO.File]::WriteAllBytes($sourcePath, $sourceBytes)
        $reportedProgress = [System.Collections.Generic.List[int]]::new()

        Save-NoteFile -Uri ([uri]$sourcePath) -DestinationPath $destinationPath -ProgressCallback {
            param($percent)
            $reportedProgress.Add($percent)
        }

        [System.IO.File]::ReadAllBytes($destinationPath) | Should -Be $sourceBytes
        $reportedProgress[-1] | Should -Be 100
    }
}

Describe "Invoke-WPFOOSU" {
    BeforeEach {
        New-NoteOOSUTestContext
        $script:capturedScriptBlock = $null
        $script:capturedParameterList = $null

        Mock Invoke-WPFRunspace {
            $script:capturedScriptBlock = $ScriptBlock
            $script:capturedParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Set-NoteTweaksProgressIndicator { }
        Mock Show-NoteMessage { }
        Mock Write-NoteLog { }
        Mock Start-Process { }
        Mock Write-Error { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedParameterList -Scope Script -ErrorAction SilentlyContinue
    }

    It "queues the download in a background runspace" {
        Invoke-WPFOOSU

        $script:sync.ProcessRunning | Should -BeTrue
        Should -Invoke Invoke-WPFRunspace -Times 1 -Exactly
        $script:capturedParameterList[0][0] | Should -Be "downloadPath"
        $script:capturedParameterList[0][1] | Should -Be (Join-Path $TestDrive "ooshutup10.exe")
    }

    It "does not start while another process is running" {
        New-NoteOOSUTestContext -ProcessRunning $true

        Invoke-WPFOOSU

        Should -Invoke Show-NoteMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Another process is currently running." -and
                $Title -eq "Note" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Not -Invoke Invoke-WPFRunspace
    }

    It "maps download progress to the window indicator and launches O&O ShutUp10++" {
        Mock Save-NoteFile {
            & $ProgressCallback 35
            & $ProgressCallback 100
        }

        Invoke-WPFOOSU
        & $script:capturedScriptBlock -downloadPath $script:capturedParameterList[0][1]

        Should -Invoke Set-NoteTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Downloading O&O ShutUp10++ (0%)" -and $Percent -eq 0
        }
        Should -Invoke Set-NoteTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Downloading O&O ShutUp10++ (35%)" -and $Percent -eq 35
        }
        Should -Invoke Set-NoteTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "O&O ShutUp10++ launched" -and $Percent -eq 100
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq (Join-Path $TestDrive "ooshutup10.exe")
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "shows failure progress and clears the running state when the download fails" {
        Mock Save-NoteFile { throw "download failed" }

        Invoke-WPFOOSU
        & $script:capturedScriptBlock -downloadPath $script:capturedParameterList[0][1]

        Should -Invoke Set-NoteTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "O&O ShutUp10++ download failed" -and $Percent -eq 100
        }
        Should -Not -Invoke Start-Process
        Should -Invoke Write-Error -Times 1 -Exactly
        $script:sync.ProcessRunning | Should -BeFalse
    }
}
