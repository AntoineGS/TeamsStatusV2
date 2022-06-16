<#
.NOTES
    Name: Get-TeamsStatus.ps1
    Original Author: Danny de Vries
    Maintainer: 
    Requires: PowerShell v2 or higher
    Version History: https://github.com/EBOOZ/TeamsStatus/commits/main
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
. ($PSScriptRoot + "\Settings.ps1")
. ($PSScriptRoot + "\Lang-$Lang.ps1")
. ($PSScriptRoot + "\TSFunctions.ps1")

# Some variables
$HAToken = if ([string]::IsNullOrEmpty($env:TSHATOKEN)) {$settingsHAToken} else {$env:TSHATOKEN}
$HAUrl = if ([string]::IsNullOrEmpty($env:TSHAURL)) {$settingsHAUrl} else {$env:TSHAURL}

$headers = @{"Authorization"="Bearer $HAToken";}
$statusActivityHash = @{
    $lgAvailable = "Available"
    $lgBusy = "Busy"
    $lgAway = "Away"
    $lgBeRightBack = "BeRightBack"
    $lgDoNotDisturb = "DoNotDisturb"
    $lgFocusing = "Focusing"
    $lgPresenting = "Presenting"
    $lgInAMeeting = "InAMeeting"
    $lgOffline = "Offline"
}

# Ensure these are initialized to null so the first hit triggers an update in HA
$CurrentStatus = $null
$CurrentActivity = $null
$CurrentWebcamStatus = $null

# Some defaults
$WebcamStatus = $lgCameraOff
$WebcamIcon = "mdi:camera-off"
$defaultIcon = "mdi:microsoft-teams"

# Run the script when a parameter is used and stop when done
If($null -ne $SetStatus){
    InvokeHA -state $SetStatus -friendlyName $entityStatusName -icon $defaultIcon -entityId $entityStatusId
    break
}

# Start monitoring the Teams logfile when no parameter is used to run the script
Get-Content -Path "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Teams\logs.txt" -Encoding Utf8 -Tail 1000 -ReadCount 0 -Wait | % {
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
        'name: desktop_call_state_change_send, isOngoing' | Select-Object -Last 1

    # Get Teams application process
    $TeamsProcess = Get-Process -Name Teams -ErrorAction SilentlyContinue

    # Check if Teams is running and start monitoring the log if it is
    If ($null -ne $TeamsProcess) {
        If($TeamsStatus -eq $null){ }
        ElseIf($TeamsStatus -like "*Setting the taskbar overlay icon - $lgOnThePhone*" -or `
               $TeamsStatus -like "*StatusIndicatorStateService: Added OnThePhone*") {
                $Status = $lgBusy    
        }
        Else {
            $statusActivityHash.GetEnumerator() | ForEach-Object {
                If ($TeamsStatus -like "*Setting the taskbar overlay icon - $($_.key)*" -or `
                    $TeamsStatus -like "*StatusIndicatorStateService: Added $($_.value)*" -or `
                    $TeamsStatus -like "*StatusIndicatorStateService: Added NewActivity (current state: $($_.value) -> NewActivity*") {
                    $Status = $($_.key)
                }
            }
        }
        
        If($TeamsActivity -eq $null){ }
        ElseIf ($TeamsActivity -like "*Resuming daemon App updates*" -or `
                $TeamsActivity -like "*SfB:TeamsNoCall*" -or `
                $TeamsActivity -like "*name: desktop_call_state_change_send, isOngoing: false*") {
            $Activity = $lgNotInACall
            $ActivityIcon = $iconNotInACall
        }
        ElseIf ($TeamsActivity -like "*Pausing daemon App updates*" -or `
                $TeamsActivity -like "*SfB:TeamsActiveCall*" -or `
                $TeamsActivity -like "*name: desktop_call_state_change_send, isOngoing: true*") {
            $Activity = $lgInACall
            $ActivityIcon = $iconInACall
        }
    }
    # Set status to Offline when the Teams application is not running
    Else {
        $Status = $lgOffline
        $Activity = $lgNotInACall
        $ActivityIcon = $iconNotInACall
    }
    
    Write-Host "Teams Status: $Status"
    Write-Host "Teams Activity: $Activity"

    # Webcam support (sensor.teams_cam_status)
    # While in a call, we poke the registry for cam status (maybe too often), but I could not find a log to maches a trigger 
      # to turn on and off the camera so it might be hit or miss, moreso when leaving a call to ensure something 
      # triggers the log to set it to Off
    If($Activity -eq $lgInACall -or $WebcamStatus -eq $lgCameraOn) {
        $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam\NonPackaged\" + 
                        "C:#Users#$env:USERNAME#AppData#Local#Microsoft#Teams#current#Teams.exe"

        $webcam = Get-ItemProperty -Path $registryPath -Name LastUsedTimeStop | select LastUsedTimeStop

        if ($webcam.LastUsedTimeStop -eq 0) {
	        $WebcamStatus = $lgCameraOn
	        $WebcamIcon = "mdi:camera"
        }
        else {
	        $WebcamStatus = $lgCameraOff
	        $WebcamIcon = "mdi:camera-off"
        }
    }

    # Call Home Assistant API to set the status and activity sensors
    If ($CurrentStatus -ne $Status -and $Status -ne $null) {
        $CurrentStatus = $Status

        # Use default credentials in the case of a proxy server
        $Wcl = new-object System.Net.WebClient
        $Wcl.Headers.Add("user-agent", "PowerShell Script")
        $Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials 
        InvokeHA -state $CurrentStatus -friendlyName $entityStatusName -icon $defaultIcon -entityId $entityStatusId
    }

    If ($CurrentActivity -ne $Activity) {
        $CurrentActivity = $Activity
        InvokeHA -state $Activity -friendlyName $entityActivityName -icon $ActivityIcon -entityId $entityActivityId
    }

    If ($null -ne $WebcamStatus -and $CurrentWebcamStatus -ne $WebcamStatus) {
        $CurrentWebcamStatus = $WebcamStatus
        InvokeHA -state $WebcamStatus -friendlyName $entityCamStatusName -icon $WebcamIcon -entityId $entityCamStatusId
    }
}