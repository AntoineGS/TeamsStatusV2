# Does the call to Home Assistant's API
function InvokeHA {
    param ([string]$state, [string]$friendlyName, [string]$icon, [string]$entityId)

    $headers = @{"Authorization"="Bearer $HAToken"}
    # Use default credentials in the case of a proxy server, not sure if this is doing anything as $Wcl is not used anywhere
    $Wcl = new-object System.Net.WebClient
    $Wcl.Headers.Add("user-agent", "PowerShell Script")
    $Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials 

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

function GetAppDataFolder {
    $userName = GetUserName
    return "C:\Users\$userName\AppData\Roaming"
}

function GetFirstNonEmpty{
	param([string]$firstString, [string]$secondString)
	$result = if ([string]::IsNullOrEmpty($firstString)) {$secondString} else {$firstString}
	return $result
}

function GetUserName {
	$configUser = $env:TSUSERNAME 
	$actualUser = $env:USERNAME
    $result = GetFirstNonEmpty -firstString $configUser -secondString $actualUser
	return $result
}
