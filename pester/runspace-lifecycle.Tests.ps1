#===========================================================================
# Tests - Runspace lifecycle
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Close-NoteRunspacePool.ps1")
    . (Join-Path $script:repoRoot "functions\private\Initialize-NoteRunspacePool.ps1")
}

Describe "Initialize-NoteRunspacePool" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{})
        $script:PARAM_OFFLINE = $false
    }

    AfterEach {
        Close-NoteRunspacePool
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name PARAM_OFFLINE -Scope Script -ErrorAction SilentlyContinue
    }

    It "creates and reuses one open runspace pool" {
        $firstPool = Initialize-NoteRunspacePool
        $secondPool = Initialize-NoteRunspacePool

        $firstPool.RunspacePoolStateInfo.State | Should -Be ([System.Management.Automation.Runspaces.RunspacePoolState]::Opened)
        [object]::ReferenceEquals($firstPool, $secondPool) | Should -BeTrue
    }

    It "closes and removes the active runspace pool" {
        $pool = Initialize-NoteRunspacePool

        Close-NoteRunspacePool

        $pool.RunspacePoolStateInfo.State | Should -Be ([System.Management.Automation.Runspaces.RunspacePoolState]::Closed)
        $script:sync.ContainsKey("runspace") | Should -BeFalse
    }
}

Describe "Runspace startup wiring" {
    It "does not create the GUI runspace pool before automation checks" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw
        $beforePreset = $mainScript.Substring(0, $mainScript.IndexOf('if ($Preset)'))

        $beforePreset | Should -Not -Match '\[runspacefactory\]::CreateRunspacePool'
        $beforePreset | Should -Not -Match '\$sync\.runspace\.Open\(\)'
    }

    It "initializes runspaces synchronously for automation paths and after first render for GUI" {
        $mainScript = Get-Content -Path (Join-Path $script:repoRoot "scripts\main.ps1") -Raw

        $mainScript | Should -Match 'if \(\$Preset\) \{\s+Initialize-NoteRunspacePool'
        $mainScript | Should -Match 'if \(\$Config\) \{\s+Initialize-NoteRunspacePool'
        $mainScript | Should -Match 'Dispatcher\.BeginInvoke\(\[System\.Windows\.Threading\.DispatcherPriority\]::Background, \[action\]\{ Initialize-NoteRunspacePool'
        $mainScript | Should -Match 'Close-NoteRunspacePool'
    }

    It "creates runspaces on demand before queueing background work" {
        $runspaceScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFRunspace.ps1") -Raw

        $runspaceScript | Should -Match 'Initialize-NoteRunspacePool \| Out-Null'
    }
}
