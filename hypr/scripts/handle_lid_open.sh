#!/bin/zsh
INTERNAL_MONITOR="eDP-1"
EXTERNAL_MONITOR="HDMI-A-1"

handle_monitor() {
  hyprctl keyword monitor "$INTERNAL_MONITOR, 3025x1890@60, 0x0, 2"
  hyprctl keyword monitor "$EXTERNAL_MONITOR, 2560x1440@120, 1512x0, 1.33"
}

move_workspaces() {
  local workspace_number="$1"
  hyprctl dispatch moveworkspacetomonitor "$workspace_number" "$INTERNAL_MONITOR"
}

handle_monitor

move_workspaces 1
move_workspaces 2
move_workspaces 3
move_workspaces 4
