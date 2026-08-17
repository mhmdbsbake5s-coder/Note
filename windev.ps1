# Runs the pre-release version of Note

$latestTag = (Invoke-RestMethod https://api.github.com/repos/ChrisTitusTech/Note/tags).Name | Select-Object -First 1
$uri = "https://github.com/ChrisTitusTech/Note/releases/download/$latestTag/Note.ps1"
$scriptPath = Join-Path $env:TEMP "Note-$latestTag.ps1"

Invoke-WebRequest -Uri $uri -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop

$executable = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
$currentPowerShell = Join-Path $PSHOME $executable
& $currentPowerShell -ExecutionPolicy Bypass -NoProfile -File $scriptPath
