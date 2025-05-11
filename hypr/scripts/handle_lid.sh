#!/bin/bash
INTERNAL_MONITOR="eDP-1"
EXTERNAL_MONITOR="HDMI-A-1"

arg="$1"

handle_monitor() {
  if [ "$arg" = "open" ]; then
    hyprctl keyword monitor "$INTERNAL_MONITOR, 3025x1890@60, 0x0, 2"
    hyprctl keyword monitor "$EXTERNAL_MONITOR, 2560x1440@120, 1512x0, 1.33"
  else
    hyprctl keyword monitor "$INTERNAL_MONITOR, disable"
    hyprctl keyword monitor "$EXTERNAL_MONITOR, 2560x1440@120, 1512x0, 1.33"
  fi
}

move_workspaces() {
  local workspace_number="$1"

  [[ "$arg" = "open" ]] && monitor="$INTERNAL_MONITOR" || monitor="$EXTERNAL_MONITOR"

  hyprctl dispatch moveworkspacetomonitor "$workspace_number" "$monitor"
}

if [ "$arg" = "open" ]; then
  handle_monitor
fi

move_workspaces 1
move_workspaces 2
move_workspaces 3
move_workspaces 4

if [ "$arg" = "close" ]; then
  handle_monitor
fi
