#!/bin/bash
STATE_FILE="/tmp/waybar-visible"

# [ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

get_current_workspace() {
    niri msg --json workspaces | jq '.[] | select(.is_active == true) | .id'
}

count_windows_in_current_workspace() {
    current_ws=$(get_current_workspace)
    niri msg --json windows | jq "[.[] | select(.workspace_id == $current_ws)] | length"
}

toggle_waybar() {
    killall -SIGUSR1 waybar
}

show_waybar() {
    if [ ! -f "$STATE_FILE" ]; then
        toggle_waybar
        touch "$STATE_FILE"
    fi
}

hide_waybar() {
    if [ -f "$STATE_FILE" ]; then
        toggle_waybar
        rm -f "$STATE_FILE"
    fi
}

# Initial check
count=$(count_windows_in_current_workspace)
if [[ $count -eq 0 ]]; then
    show_waybar
else
    hide_waybar
fi

# Listen for events
niri msg --json event-stream | while read -r line; do
    echo "$line"
    if echo "$line" | jq -e '.WindowClosed or .WindowOpenedOrChanged or .WorkspaceActivated or .WindowFocusChanged' >/dev/null; then
        count=$(count_windows_in_current_workspace)
        if [[ $count -eq 0 ]]; then
            show_waybar
        else
            hide_waybar
        fi
    elif echo "$line" | jq -e '.OverviewOpenedOrClosed | .is_open'; then
        show_waybar
    fi
done
