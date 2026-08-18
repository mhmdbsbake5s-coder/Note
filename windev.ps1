# Runs the pre-release version of Note

$latestTag = (Invoke-RestMethod https://api.github.com/repos/mhmdbsbake5s-coder/note/tags).Name | Select-Object -First 1
$uri = "https://github.com/mhmdbsbake5s-coder/note/releases/download/$latestTag/Note.ps1"
$scriptPath = Join-Path $env:TEMP "Note-$latestTag.ps1"

Invoke-WebRequest -Uri $uri -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop

$executable = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
$currentPowerShell = Join-Path $PSHOME $executable
& $currentPowerShell -ExecutionPolicy Bypass -NoProfile -File $scriptPath
