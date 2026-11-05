#!/bin/bash

# Raycast Script Command Template
#
# Duplicate this file and remove ".template." from the filename to get started.
# See full documentation here: https://github.com/raycast/script-commands
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Rzkill
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Raycast Scripts

# Click on the main display to ensure focpkill console-build;
pkill dlv
pkill yak
pkill npm
pkill yarn
pkill webpack
pkill buffalo
pkill node
pkill console-build
pkill bat
pkill tail

kill_port() {
    lsof -ti tcp:$1 | xargs -r kill -9
}

kill_port 3000
#kill_port 2345
