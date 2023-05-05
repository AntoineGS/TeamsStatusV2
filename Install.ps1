. ($PSScriptRoot + "\Settings.ps1")
. ($PSScriptRoot + "\TSFunctions.ps1")

$appDataFolder = GetAppDataFolder

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File $PSScriptRoot\Settings.ps1
Unblock-File $PSScriptRoot\Lang-*.ps1
Unblock-File $PSScriptRoot\Get-TeamsStatus.ps1
Unblock-File $PSScriptRoot\TSFunctions.ps1
Unblock-File $PSScriptRoot\Uninstall.ps1

$TargetFile = $PSScriptRoot + "\Start.cmd"
$ShortcutFile = "$appDataFolder\Microsoft\Windows\Start Menu\Programs\Startup\Start TeamsStatus.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Save()

Write-Output ""
Write-Output "Installation completed."
Write-Output "Please either reboot or launch the shortcut manually here:"
Write-Output "  $ShortcutFile"
Write-Output ""