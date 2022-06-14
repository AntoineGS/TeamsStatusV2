function UninstallService {
    Stop-Service -Name "Microsoft Teams Status Monitor"
    Start-Process -FilePath $PSScriptRoot\nssm.exe -ArgumentList 'remove "Microsoft Teams Status Monitor" confirm' -NoNewWindow -Wait
}

UninstallService