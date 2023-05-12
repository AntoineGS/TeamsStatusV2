# TeamsStatus

## Introduction
This PowerShell script/service uses the local Teams' log file to track the status and activity of the logged in Teams user.
Microsoft provides the status of your account via the Graph API, however to access the Graph API, your organization needs to grant consent for the organization so everybody can read their Teams status.
This solution is great for anyone who's organization does not allow this.

This script makes use of three sensors that are created in Home Assistant up front:

* `sensor.teams_status`: displays that availability status of your Teams client based on the icon overlay in the taskbar on Windows.
* `sensor.teams_activity`: shows if you are in a call or not based on the App updates deamon, which is paused as soon as you join a call.
* `sensor.teams_cam_status`: shows if you have your webcam turned on or not during a call.

## Important
This solution is created to work with Home Assistant. 
It could be adapted to work with any home automation platform that provides an API, but you would probably need to change the PowerShell code.

## Installation
* Create the three Microsoft Teams sensors in the Home Assistant `configuration.yaml` file:

  ```yaml
  # configuration.yaml

  template:
    - sensor:
      - name: teams_status
        unique_id: e4f476369caf
        state: "{{ None }}"
      - name: teams_activity
        unique_id: 8b2cc27ca7eb
        state: "{{ None }}"
      - name: teams_cam_status
        unique_id: 3f37d7f25d67
        state: "{{ None }}"
  ```

  Their icons and friendly names will be automatically set by this script.

* Generate a Long-lived access token ([see HA documentation](https://developers.home-assistant.io/docs/auth_api/#long-lived-access-token))
* Copy and temporarily save the token somewhere you can find it later
* Restart Home Assistant to have the new sensors added
* Download the files from this repository and save them to any folder (we will use C:\Scripts in this example)
* Configure the script using Environment Variables
  * Add a variable `TSHATOKEN` with the token you generated (ie: eyJ0eXAiOiJKV1... with many more characters)
  * Add a variable `TSHAURL` with the URL to your Home Assistant server (ie: https://yourha.duckdns.org or http://192.168.1.50:8123)
  * Optional: Add a variable `TSUSERNAME` with your Windows username, if not set it will get it from Windows
  * Optional: Add a variable `TSLANG` with a supported language (en, nl)
* Start a elevated PowerShell prompt, and execute the following scripts
  ```powershell
  Unblock-File C:\Scripts\Install.ps1
  C:\Scripts\Install.ps1
  ```
* Execute the file as requested in the Install.ps1 output
* After completing the steps above, start your Teams client and verify if the status and activity is updated as expected.
  
## Uninstallation
You can uninstall the service by executing the `Uninstall.ps1` script.
Using the previous path as an example, in PowerShell you would run:
  ```powershell
  C:\Scripts\Uninstall.ps1
  ```
Note: This will not stop the script if it is currently executing, if you would like to do so just kill it (powershell.exe).
If you get an error that the file "is not is not digitally signed", simply run the following before executing the uninstaller again:
  ```powershell
  Unblock-File C:\Scripts\Uninstall.ps1
  ```

## Contribution
Pull Requests are welcomed!

## Credit
Original work by EBOOZ, which can be found here: https://github.com/EBOOZ/TeamsStatus.
As the project seemed abandoned with multiple PRs not being addressed it has been cloned into this repo.
