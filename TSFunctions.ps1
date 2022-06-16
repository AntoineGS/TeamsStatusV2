function UninstallService {
    Stop-Service -Name "Microsoft Teams Status Monitor"
    Start-Process -FilePath $PSScriptRoot\nssm.exe -ArgumentList 'remove "Microsoft Teams Status Monitor" confirm' -NoNewWindow -Wait
}

# Does the call to Home Assistant's API
function InvokeHA {
    param ([string]$state, [string]$friendlyName, [string]$icon, [string]$entityId)

    Write-Host ("Setting <"+$friendlyName+"> to <"+$state+">:")
    $params = @{
        "state"="$state";
        "attributes"= @{
            "friendly_name"="$friendlyName"; # Redundant as it is already in HA but without it HA resets it to the sensor id
            "icon"="$icon";
        }
    }
     
    $params = $params | ConvertTo-Json
    Invoke-RestMethod -Uri "$HAUrl/api/states/$entityId" -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($params)) -ContentType "application/json"    
}