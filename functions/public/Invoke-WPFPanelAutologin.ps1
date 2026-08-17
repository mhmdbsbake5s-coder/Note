function Invoke-WPFPanelAutologin {
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile "$Notedir\autologin.exe"
    Start-Process -FilePath "$Notedir\autologin.exe" -ArgumentList /accepteula
}
