# Set icons to use for call activity
$iconInACall = "mdi:phone-in-talk"
$iconIncomingCall = "mdi:phone-incoming"
$iconNotInACall = "mdi:phone-off"

# Set entities to post to
# Friendly names are required or they get reset in HA through the API...
$entityStatusId = "sensor.microsoft_teams_status"
$entityStatusName = "Microsoft Teams status"
$entityActivityId = "sensor.microsoft_teams_activity"
$entityActivityName = "Microsoft Teams activity"
$entityCamStatusId = "sensor.microsoft_teams_camera_status"
$entityCamStatusName = "Microsoft Teams camera status"