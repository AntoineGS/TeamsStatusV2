. ($PSScriptRoot + "\Settings.ps1")
. ($PSScriptRoot + "\TSFunctions.ps1")

$installPath = $env:TSINSTALLPATH
$appDataFolder = GetAppDataFolder

if ($PSScriptRoot -ne $installPath) {
	Write-Output 'Please set up the environment variable "TSINSTALLPATH" or the "$installPath" variable in the Settings.ps1 file before running this.'
	Exit
}

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
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
$Shortcut.Save()

Write-Output ""
Write-Output "Installation completed."
Write-Output "Please either reboot or launch the shortcut manually here:"
Write-Output "  $ShortcutFile"
Write-Output ""