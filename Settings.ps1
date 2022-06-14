# Configure the variables below that will be used in the script
$SettingsHAToken = "<Insert token>" # Example: eyJ0eXAiOiJKV1...
$SettingsUserName = "<UserName>" # When not sure, open a command prompt and type: echo %USERNAME%
$SettingsHAUrl = "<HAUrl>" # Example: https://yourha.duckdns.org or http://192.168.1.50:8123

# Set language variables below (ie: en, nl)
$Lang = "en"

# Set icons to use for call activity
$iconInACall = "mdi:phone-in-talk-outline"
$iconNotInACall = "mdi:phone-off"
$iconMonitoring = "mdi:api"

# Set entities to post to
$entityStatus = "sensor.teams_status"
$entityStatusName = "Microsoft Teams status"
$entityActivity = "sensor.teams_activity"
$entityActivityName = "Microsoft Teams activity"
$entityHeartbeat = "binary_sensor.teams_monitoring"
$entityHeartbeatName = "Microsoft Teams monitoring"
