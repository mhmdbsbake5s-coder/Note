# make-keys.ps1
# Generates valid Note licence keys.
# The salt here MUST match the one in Test-NoteLicense.ps1.

param(
    [int]$Count = 10
)

$salt = "N0te-2026-Wx7"

function Get-Checksum {
    param([string]$Body)
    $seed = "$Body$salt"
    $sum = 0
    for ($i = 0; $i -lt $seed.Length; $i++) {
        $sum += ([int][char]$seed[$i]) * ($i + 3)
    }
    $sum = $sum % 1679616
    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $out = ""
    for ($i = 0; $i -lt 4; $i++) {
        $out = $chars[$sum % 36] + $out
        $sum = [math]::Floor($sum / 36)
    }
    return $out
}

$chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"   # no I, O, 0, 1 - easy to misread
$rand = New-Object System.Random

Write-Host ""
Write-Host "Generated keys:" -ForegroundColor Green
Write-Host ""

$keys = @()

for ($n = 0; $n -lt $Count; $n++) {
    $a = ""
    $b = ""
    for ($i = 0; $i -lt 4; $i++) { $a += $chars[$rand.Next(0, $chars.Length)] }
    for ($i = 0; $i -lt 4; $i++) { $b += $chars[$rand.Next(0, $chars.Length)] }
    $check = Get-Checksum "$a$b"
    $key = "NOTE-$a-$b-$check"
    $keys += $key
    Write-Host "  $key" -ForegroundColor White
}

$outFile = ".\keys.txt"
$keys | Out-File -FilePath $outFile -Encoding UTF8
Write-Host ""
Write-Host "Saved to $outFile" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: do not commit keys.txt to GitHub." -ForegroundColor Yellow
Write-Host "Add it to .gitignore." -ForegroundColor Yellow
Write-Host ""
Write-Host "Generate more with:  .\make-keys.ps1 -Count 50" -ForegroundColor Cyan
Write-Host ""
