. ($PSScriptRoot + "\TSFunctions.ps1")
. ($PSScriptRoot + "\Settings.ps1")

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Unblock-File $PSScriptRoot\Settings.ps1
Unblock-File $PSScriptRoot\Lang-*.ps1
Unblock-File $PSScriptRoot\Get-TeamsStatus.ps1
Unblock-File $PSScriptRoot\TSFunctions.ps1

# In case this is re-run as a reinstall
# If you get a "Cannot find any service with service name" do not worry about it as it just means the service was not installed yet
UninstallService

# Enable logging if active
if ($enableLogs -eq "Y") {
    $loggingParam = "2>&1 | tee -filePath $PSScriptRoot\TeamsStatusLog.txt"
}

$ArgumentList = 'install "Microsoft Teams Status Monitor" "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-command "& { . ' + 
    "$PSScriptRoot\Get-TeamsStatus.ps1 $loggingParam" + '}"" '
Start-Process -FilePath $PSScriptRoot\nssm.exe -ArgumentList $ArgumentList -NoNewWindow -Wait

$Prompt = "Please enter the password for user " + $env:USERNAME
$Password = Read-Host -Prompt $Prompt 
$ArgumentList = 'set "Microsoft Teams Status Monitor" ObjectName .\' + "$env:USERNAME $Password"
Start-Process -FilePath $PSScriptRoot\nssm.exe -ArgumentList $argumentList -NoNewWindow -Wait 
Start-Service -Name "Microsoft Teams Status Monitor"