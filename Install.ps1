. ($PSScriptRoot + "\Settings.ps1")

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Unblock-File $PSScriptRoot\Settings.ps1
Unblock-File $PSScriptRoot\Lang-*.ps1
Unblock-File $PSScriptRoot\Get-TeamsStatus.ps1
Unblock-File $PSScriptRoot\TSFunctions.ps1
Unblock-File $PSScriptRoot\Uninstall.ps1

# Enable logging if active
if ($enableLogs -eq "Y") {
    $loggingParam = "2>&1 | tee -filePath $PSScriptRoot\TeamsStatusLog.txt"
}

$TargetFile = "wscript"
$Arguments = "C:\Scripts\Start.vbs"
$ShortcutFile = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Start TeamsStatus.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = $Arguments
$Shortcut.Save()
