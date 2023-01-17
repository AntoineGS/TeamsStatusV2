. ($PSScriptRoot + "\TSFunctions.ps1")
$appDataFolder = GetAppDataFolder
$filename = "$appDataFolder\Microsoft\Windows\Start Menu\Programs\Startup\Start TeamsStatus.lnk"

if (Test-Path $filename) {
  Remove-Item $filename
}