#===========================================================================
# Tests - Package Selection and Package Managers
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Get-NoteSelectedPackages.ps1")
    . (Join-Path $script:repoRoot "functions\private\Test-NotePackageManager.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-NoteProgramWinget.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-NoteProgramChoco.ps1")

    function Invoke-WPFUIThread { }
    function Write-NoteLog { }
}

Describe "Get-NoteSelectedPackages" {
    BeforeEach {
        Mock Invoke-WPFUIThread { }
    }

    It "uses winget IDs when winget is preferred" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "vlc" }
        )

        $result = Get-NoteSelectedPackages -PackageList $packages -Preference "Winget"

        (@($result["Winget"]) -join "|") | Should -Be "Git.Git|VideoLAN.VLC"
        @($result["Choco"]).Count | Should -Be 0
    }

    It "uses choco IDs and falls back to winget for na or missing choco IDs" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "na" }
            [pscustomobject]@{ winget = "Mozilla.Firefox" }
        )

        $result = Get-NoteSelectedPackages -PackageList $packages -Preference "Choco"

        (@($result["Choco"]) -join "|") | Should -Be "git"
        (@($result["Winget"]) -join "|") | Should -Be "VideoLAN.VLC|Mozilla.Firefox"
    }

    It "skips blank, na, and missing package IDs" {
        $packages = @(
            [pscustomobject]@{ winget = ""; choco = "" }
            [pscustomobject]@{ winget = "na"; choco = "na" }
            [pscustomobject]@{ choco = "only-choco" }
            [pscustomobject]@{ winget = "   " }
        )

        $result = Get-NoteSelectedPackages -PackageList $packages -Preference "Winget"

        @($result["Winget"]).Count | Should -Be 0
        @($result["Choco"]).Count | Should -Be 0
    }

    It "deduplicates package IDs" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "vlc" }
        )

        $result = Get-NoteSelectedPackages -PackageList $packages -Preference "Choco"

        (@($result["Choco"]) -join "|") | Should -Be "git|vlc"
        @($result["Winget"]).Count | Should -Be 0
    }

    It "returns empty package lists for an empty selection" {
        $result = Get-NoteSelectedPackages -PackageList @() -Preference "Winget"

        @($result["Winget"]).Count | Should -Be 0
        @($result["Choco"]).Count | Should -Be 0
    }
}

Describe "Test-NotePackageManager" {
    BeforeEach {
        Mock Write-Host { }
    }

    It "reports winget installed when the command exists" {
        Mock Get-Command {
            [pscustomobject]@{ Name = "winget" }
        } -ParameterFilter { $Name -eq "winget" -and $ErrorAction -eq "SilentlyContinue" }

        Test-NotePackageManager -winget | Should -Be "installed"

        Should -Invoke -CommandName Get-Command -Times 1 -Exactly -ParameterFilter {
            $Name -eq "winget" -and $ErrorAction -eq "SilentlyContinue"
        }
    }

    It "reports choco not installed when the command is missing" {
        Mock Get-Command {
            $null
        } -ParameterFilter { $Name -eq "choco" -and $ErrorAction -eq "SilentlyContinue" }

        Test-NotePackageManager -choco | Should -Be "not-installed"

        Should -Invoke -CommandName Get-Command -Times 1 -Exactly -ParameterFilter {
            $Name -eq "choco" -and $ErrorAction -eq "SilentlyContinue"
        }
    }
}

Describe "Install-NoteProgramWinget" {
    BeforeEach {
        Mock Write-NoteLog { }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    }

    It "starts winget with install arguments" {
        Install-NoteProgramWinget -Action Install -Programs @("Git.Git")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and
                (@($ArgumentList) -join "|") -eq "install|--id|Git.Git|--accept-package-agreements|--accept-source-agreements|--source|winget|--silent" -and
                $NoNewWindow -eq $true -and
                $Wait -eq $true -and
                $PassThru -eq $true
        }
    }

    It "starts winget with uninstall arguments and msstore source when requested" {
        Install-NoteProgramWinget -Action Uninstall -Programs @("msstore:9NBLGGH4NNS1")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and
                (@($ArgumentList) -join "|") -eq "uninstall|--id|9NBLGGH4NNS1|--source|msstore|--silent"
        }
    }

    It "skips whitespace and na package IDs" {
        Install-NoteProgramWinget -Action Install -Programs @(" ", "na")

        Should -Invoke -CommandName Start-Process -Times 0 -Exactly
    }
}

Describe "Install-NoteProgramChoco" {
    BeforeEach {
        Mock Write-NoteLog { }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    }

    It "starts choco with install arguments" {
        Install-NoteProgramChoco -Action Install -Programs @("git", "vlc")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "choco" -and
                $ArgumentList -eq "install git vlc -y" -and
                $NoNewWindow -eq $true -and
                $Wait -eq $true -and
                $PassThru -eq $true
        }
    }

    It "starts choco with uninstall arguments" {
        Install-NoteProgramChoco -Action Uninstall -Programs @("git")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "choco" -and $ArgumentList -eq "uninstall git -y"
        }
    }
}
