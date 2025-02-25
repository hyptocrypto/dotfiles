#!/bin/bash

# Raycast Script Command Template
#
# Duplicate this file and remove ".template." from the filename to get started.
# See full documentation here: https://github.com/raycast/script-commands
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title OpenBrave
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Raycast Scripts
#!/bin/bash

# Click on the main display to ensure focus before switching spaces
cliclick c:200,200
sleep 0.1

# Switch to the rightmost space
osascript -e 'tell application "System Events"
        key code 124 using control down
        key code 124 using control down
        key code 124 using control down
        delay 0.2
end tell'

sleep 0.1

# Click to attempt focus (sometimes needed)
cliclick c:200,200
sleep 0.1
cliclick c:200,200
cliclick c:200,200
cliclick c:200,200
