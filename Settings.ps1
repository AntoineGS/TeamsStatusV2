# Set icons to use for call activity
$iconInACall = "mdi:phone-in-talk"
$iconIncomingCall = "mdi:phone-incoming"
$iconNotInACall = "mdi:phone-off"

# Set entities to post to
# Friendly names are required or they get reset in HA through the API...
$entityStatusId = "sensor.teams_status"
$entityStatusName = "Microsoft Teams Status"
$entityActivityId = "sensor.teams_activity"
$entityActivityName = "Microsoft Teams Activity"
$entityCamStatusId = "sensor.teams_cam_status"
$entityCamStatusName = "Microsoft Teams Camera Status"