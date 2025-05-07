#!/bin/zsh
INTERNAL_MONITOR="eDP-1"
EXTERNAL_MONITOR="HDMI-A-1"

handle_monitor() {
  hyprctl keyword monitor "$INTERNAL_MONITOR, disable"
  hyprctl keyword monitor "$EXTERNAL_MONITOR, 2560x1440@120, 0x0, 1.33"
}

move_workspaces() {
  local workspace_number="$1"
  hyprctl dispatch moveworkspacetomonitor "$workspace_number" "$EXTERNAL_MONITOR"
}


move_workspaces 1
move_workspaces 2
move_workspaces 3
move_workspaces 4

handle_monitor
