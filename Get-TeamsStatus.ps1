<#
.NOTES
    Name: Get-TeamsStatus.ps1
    Original Author: Danny de Vries
    Maintainer: Antoine G Simard
    Requires: PowerShell v2 or higher
    GitHub: https://github.com/AntoineGS/TeamsStatusV2
.SYNOPSIS
    Sets the status of the Microsoft Teams client to Home Assistant.
.DESCRIPTION
    This script is monitoring the Teams client logfile for certain changes. It
    makes use of two sensors that are created in Home Assistant up front.
    The status entity (sensor.teams_status by default) displays that availability 
    status of your Teams client based on the icon overlay in the taskbar on Windows. 
    The activity entity (sensor.teams_activity by default) shows if you
    are in a call or not based on the App updates deamon, which is paused as soon as 
    you join a call.
.PARAMETER SetStatus
    Run the script with the SetStatus-parameter to set the status of Microsoft Teams
    directly from the commandline.
.EXAMPLE
    .\Get-TeamsStatus.ps1 -SetStatus "Offline"
#>
# Configuring parameter for interactive run
Param($SetStatus)

# Import Settings PowerShell script
. ($PSScriptRoot + "\TSFunctions.ps1")
. ($PSScriptRoot + "\Settings.ps1")
$locLang = GetSysVar -envVar $env:TSLANG -localVar $Lang
. ($PSScriptRoot + "\Lang-$locLang.ps1")

# Some variables
$HAToken = GetSysVar -envVar $env:TSHATOKEN -localVar $settingsHAToken
$HAUrl = GetSysVar -envVar $env:TSHAURL -localVar $settingsHAUrl
#Both are stored as system variables, TSUSERNAME is one defined just for use while USERNAME is Windows
$Username = GetSysVar -envVar $env:TSUSERNAME -localVar $env:USERNAME

$teamsStatusHash = @{
    # Teams short name = @{Teams long name = HA display name}
    # Can be set manually in Teams
    "Available" = @{"Available" = $tsAvailable}
    "Busy" = @{"Busy" = $tsBusy}
    "Away" = @{"Away" = $tsAway}
    "BeRightBack" = @{"Be right back" = $tsBeRightBack}
    "DoNotDisturb" = @{"Do not disturb" = $tsDoNotDisturb}
    "Offline" = @{"Offline" = $tsOffline}
    # Automated statuses
    "Focusing" = @{"Focusing" = $tsFocusing}
    "Presenting" = @{"Presenting" = $tsPresenting}
    "InAMeeting" = @{"In a meeting" = $tsInAMeeting}
    "OnThePhone" = @{"On the phone" = $tsOnThePhone}
}

# Ensure these are initialized to null so the first hit triggers an update in HA
$currentStatus = $null
$currentActivity = $null
$currentCamStatus = $null

# Some defaults
$camStatus = $csCameraOff
$camIcon = "mdi:camera-off"
$defaultIcon = "mdi:microsoft-teams"

# Run the script when a parameter is used and stop when done
If($null -ne $SetStatus){
    InvokeHA -state $SetStatus -friendlyName $entityStatusName -icon $defaultIcon -entityId $entityStatusId
    break
}

# Start monitoring the Teams logfile when no parameter is used to run the script
Get-Content -Path "C:\Users\$Username\AppData\Roaming\Microsoft\Teams\logs.txt" -Encoding Utf8 -Tail 1000 -ReadCount 0 -Wait | % {
    # Get Teams Logfile and last icon overlay status
    $TeamsStatus = $_ | Select-String -Pattern `
        'Setting the taskbar overlay icon -',`
        'StatusIndicatorStateService: Added' | Select-Object -Last 1

    # Get Teams Logfile and last app update deamon status
    $TeamsActivity = $_ | Select-String -Pattern `
        'Resuming daemon App updates',`
        'Pausing daemon App updates',`
        'SfB:TeamsNoCall',`
        'SfB:TeamsPendingCall',`
        'SfB:TeamsActiveCall',`
        'name: desktop_call_state_change_send, isOngoing',`
        'Attempting to play audio for notification type 1' | Select-Object -Last 1

    # Get Teams application process
    $TeamsProcess = Get-Process -Name Teams -ErrorAction SilentlyContinue

    # Check if Teams is running and start monitoring the log if it is
    If ($null -ne $TeamsProcess) {
        If($null -ne $TeamsStatus) {
            $teamsStatusHash.GetEnumerator() | ForEach-Object {
                If ($TeamsStatus -like "*Setting the taskbar overlay icon - $($_.value.keys[0])*" -or `
                    $TeamsStatus -like "*StatusIndicatorStateService: Added $($_.key)*" -or `
                    $TeamsStatus -like "*StatusIndicatorStateService: Added NewActivity (current state: $($_.key) -> NewActivity*") {
                    $Status = $($_.value.values[0])
                }
            }
        }
        
        If($null -ne $TeamsActivity){
            If ($TeamsActivity -like "*Resuming daemon App updates*" -or `
                    $TeamsActivity -like "*SfB:TeamsNoCall*" -or `
                    $TeamsActivity -like "*name: desktop_call_state_change_send, isOngoing: false*") {
                $Activity = $taNotInACall
                $ActivityIcon = $iconNotInACall
            }
            ElseIf ($TeamsActivity -like "*Pausing daemon App updates*" -or `
                    $TeamsActivity -like "*SfB:TeamsActiveCall*" -or `
                    $TeamsActivity -like "*name: desktop_call_state_change_send, isOngoing: true*") {
                $Activity = $taInACall
                $ActivityIcon = $iconInACall
            }
            ElseIf ($TeamsActivity -like "*Attempting to play audio for notification type 1*") {
                $Activity = $taIncomingCall
                $ActivityIcon = $iconInACall
            }
        }
    }
    # Set status to Offline when the Teams application is not running
    Else {
        $Status = $tsOffline
        $Activity = $taNotInACall
        $ActivityIcon = $iconNotInACall
    }
    
    Write-Host "Teams Status: $Status"
    Write-Host "Teams Activity: $Activity"

    # Webcam support (sensor.teams_cam_status)
    # While in a call, we poke the registry for cam status (maybe too often), but I could not find a log entry to use as a trigger 
      # to know when to check the camera status so it might be hit or miss. 
      # When leaving a call it maybe not trigger as something non-camera related needs to get logged to trigger the check.
    If($Activity -eq $taInACall -or $camStatus -eq $csCameraOn) {
        $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged\" + 
                        "C:#Users#$Username#AppData#Local#Microsoft#Teams#current#Teams.exe"

        $webcam = Get-ItemProperty -Path $registryPath -Name LastUsedTimeStop | select LastUsedTimeStop

        If ($webcam.LastUsedTimeStop -eq 0) {
	        $camStatus = $csCameraOn
	        $camIcon = "mdi:camera"
        }
        Else {
	        $camStatus = $csCameraOff
	        $camIcon = "mdi:camera-off"
        }
    }

    # Call Home Assistant API to set the status and activity sensors
    If ($currentStatus -ne $Status -and $Status -ne $null) {
        $currentStatus = $Status
        InvokeHA -state $currentStatus -friendlyName $entityStatusName -icon $defaultIcon -entityId $entityStatusId
    }

    If ($currentActivity -ne $Activity) {
        $currentActivity = $Activity
        InvokeHA -state $Activity -friendlyName $entityActivityName -icon $ActivityIcon -entityId $entityActivityId
    }

    If ($null -ne $camStatus -and $currentCamStatus -ne $camStatus) {
        $currentCamStatus = $camStatus
        InvokeHA -state $camStatus -friendlyName $entityCamStatusName -icon $camIcon -entityId $entityCamStatusId
    }
}