#!/bin/bash

FILE="/tmp/waybar-lock"

if [ -e "$FILE" ]; then
	rm "$FILE" && fyi --app-name=Waybar --expire-time=2000 --icon="$HOME/.config/fastfetch/pngs/arch.png" "Waybar mode: auto"
else
	touch "$FILE" && fyi --app-name=Waybar --expire-time=2000 --icon="$HOME/.config/fastfetch/pngs/arch.png" "Waybar mode: locked"
fi
