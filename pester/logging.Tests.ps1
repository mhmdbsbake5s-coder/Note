#===========================================================================
# Tests - Note Logging
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Write-NoteLog.ps1")
}

Describe "Write-NoteLog" {
    BeforeEach {
        $script:testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "Note-logging-$([guid]::NewGuid())"
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        Remove-Variable -Name NoteLogPath -Scope Script -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name NoteLogPath -Scope Script -ErrorAction SilentlyContinue
        Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "writes to the active timestamped session log under logs" {
        $logPath = Join-Path $script:testRoot "logs\Note_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            Notedir = $script:testRoot
            logPath = $logPath
        })

        Write-NoteLog -Component "Test" -Message "same session log"

        Test-Path -Path $logPath | Should -BeTrue
        Test-Path -Path (Join-Path $script:testRoot "Note.log") | Should -BeFalse
        Get-Content -Path $logPath -Raw | Should -Match "\[INFO\] \[Test\] same session log"
    }

    It "uses the transcript stream when logPath is not set" {
        $transcriptPath = Join-Path $script:testRoot "logs\Note_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            Notedir = $script:testRoot
            transcriptPath = $transcriptPath
        })
        Mock Add-Content { }
        Mock Write-Host { }

        Write-NoteLog -Component "Test" -Message "transcript fallback"

        Should -Invoke -CommandName Add-Content -Times 0 -Exactly
        Should -Invoke -CommandName Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -match "\[INFO\] \[Test\] transcript fallback"
        }
        Test-Path -Path (Join-Path $script:testRoot "Note.log") | Should -BeFalse
    }

    It "creates one fallback log under logs when only Notedir is available" {
        $script:sync = [hashtable]::Synchronized(@{
            Notedir = $script:testRoot
        })

        Write-NoteLog -Component "Test" -Message "first fallback entry"
        Write-NoteLog -Component "Test" -Message "second fallback entry"

        $logFiles = @(Get-ChildItem -Path (Join-Path $script:testRoot "logs") -Filter "Note_*.log")
        $logFiles.Count | Should -Be 1
        Test-Path -Path (Join-Path $script:testRoot "Note.log") | Should -BeFalse

        $content = Get-Content -Path $logFiles[0].FullName -Raw
        $content | Should -Match "first fallback entry"
        $content | Should -Match "second fallback entry"
    }

    It "does not append directly when the active log file is the transcript" {
        $logPath = Join-Path $script:testRoot "logs\Note_2026-07-01_12-00-00.log"
        $script:sync = [hashtable]::Synchronized(@{
            Notedir = $script:testRoot
            logPath = $logPath
            transcriptPath = $logPath
        })

        Mock Add-Content { throw [System.IO.IOException]::new("locked by transcript") } -ParameterFilter {
            $Path -eq $logPath -and $ErrorAction -eq "Stop"
        }
        Mock Write-Host { }
        Mock Write-Warning { }

        Write-NoteLog -Component "Test" -Message "transcript stream fallback"

        Should -Invoke -CommandName Add-Content -Times 0 -Exactly
        Should -Invoke -CommandName Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -match "\[INFO\] \[Test\] transcript stream fallback"
        }
        Should -Invoke -CommandName Write-Warning -Times 0 -Exactly
    }

}

Describe "Note startup logging path" {
    It "uses one timestamped log file under the logs directory" {
        $startScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\start.ps1") -Raw

        $startScript | Should -Match '\$sync\.logPath = "\$logdir\\Note_\$dateTime\.log"'
        $startScript | Should -Match '\$sync\.transcriptPath = \$sync\.logPath'
        $startScript | Should -Match 'Start-Transcript -Path \$sync\.logPath'
        $startScript | Should -Not -Match '\$sync\.logPath = "\$Notedir\\Note\.log"'
    }
}
