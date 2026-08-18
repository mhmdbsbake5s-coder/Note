function Invoke-NoteInstallPSProfile {
    if (-not (Get-Command wt)) {
        Write-Host "Windows Terminal not found. Installing..."
        Install-NoteWinget
        winget install Microsoft.WindowsTerminal --source winget --silent
    }

    if (-not (Get-Command pwsh)) {
        Write-Host "PowerShell 7 not found. Installing..."
        Install-NoteWinget
        winget install Microsoft.PowerShell --source winget --installer-type wix --silent
    }

    wt new-tab pwsh -NoExit -Command "irm https://github.com/mhmdbsbake5s-coder/note/raw/main/setup.ps1 | iex"
}
