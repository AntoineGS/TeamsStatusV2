<#
.NOTES
    Name: Get-TeamsStatus.ps1
    Author: Danny de Vries
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

# Some variables
$HAToken = if ([string]::IsNullOrEmpty($env:tshatoken)) {$SettingsHAToken} else {$env:tshatoken}
$HAUrl = if ([string]::IsNullOrEmpty($env:TSHAURL)) {$SettingsHAUrl} else {$env:TSHAURL}
$headers = @{"Authorization"="Bearer $HAToken";}
$defaultIcon = "mdi:microsoft-teams"
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

# Does the call to Home Assistant's API
function InvokeHA{
    param ([string]$state, [string]$friendlyName, [string]$icon, [string]$entity)

    Write-Host ("Setting Microsoft Teams <"+$entity+"> to <"+$state+">:")
    $params = @{
        "state"="$state";
        "attributes"= @{
            "friendly_name"="$friendlyName";
            "icon"="$icon";
        }
    }
     
    $params = $params | ConvertTo-Json
    Invoke-RestMethod -Uri "$HAUrl/api/states/$entity" -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($params)) -ContentType "application/json"    
}

# Run the script when a parameter is used and stop when done
If($null -ne $SetStatus){
    InvokeHA -state $SetStatus -friendlyName $entityStatusName, -icon $defaultIcon -entity $entityStatus
    break
}

# Start monitoring the Teams logfile when no parameter is used to run the script
Get-Content -Path $env:APPDATA"\Microsoft\Teams\logs.txt" -Tail 1000 -ReadCount 0 -Wait | % {
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
        If($TeamsStatus -eq $null){ 
            $Status = $null
        }
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

    # Call Home Assistant API to set the status and activity sensors
    If ($CurrentStatus -ne $Status -and $Status -ne $null) {
        $CurrentStatus = $Status

        # Use default credentials in the case of a proxy server
        $Wcl = new-object System.Net.WebClient
        $Wcl.Headers.Add("user-agent", "PowerShell Script")
        $Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials 
        InvokeHA -state $CurrentStatus -friendlyName $entityStatusName, -icon $defaultIcon -entity $entityStatus
    }

    If ($CurrentActivity -ne $Activity) {
        $CurrentActivity = $Activity
        InvokeHA -state $Activity -friendlyName $entityActivityName, -icon $ActivityIcon -entity $entityActivity
    }
}