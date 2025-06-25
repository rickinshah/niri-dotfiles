#!/bin/bash

STATE_FILE="/tmp/waybar-visible"

# Toggle Waybar visibility
killall -USR1 waybar

# Flip the state
if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi
