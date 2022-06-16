# Configure the variables below that will be used in the script, you can also use environment variables for most of them
$settingsHAToken = "<Insert token>" # Example: eyJ0eXAiOiJKV1..., can also be an environment variable named TSHATOKEN
$settingsHAUrl = "<HAUrl>" # Example: https://yourha.duckdns.org or http://192.168.1.50:8123, can also be an environment variable named TSHAURL
$settingsAppDataPath = "<App Data Path>" # When not sure, open a command prompt and type: echo %APPDATA% ; Configuration priority: the environment variable TSAPPDATAPATH, this setting then $env:APPDATA

# Set language variables below (currently supported: en, nl)
$Lang = "en"

# Set icons to use for call activity
$iconInACall = "mdi:phone-in-talk-outline"
$iconNotInACall = "mdi:phone-off"
$iconMonitoring = "mdi:api"

# Set entities to post to
# Friendly names are required or they get reset in HA through the API...
$entityStatusId = "sensor.teams_status"
$entityStatusName = "Microsoft Teams Status"
$entityActivityId = "sensor.teams_activity"
$entityActivityName = "Microsoft Teams Activity"
$entityCamStatusId = "sensor.teams_cam_status"
$entityCamStatusName = "Microsoft Teams Camera Status"

# Debugging, use to investigate when the script is not behaving as expected
$enableLogs = "N"