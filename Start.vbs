Dim WShell
Set WShell = CreateObject("WScript.Shell")
WShell.Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Scripts\Get-TeamsStatus.ps1", 0
Set WShell = Nothing
