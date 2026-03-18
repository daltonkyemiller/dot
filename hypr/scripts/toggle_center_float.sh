#!/usr/bin/env bash
# Toggle floating, resize to 16:9 centered under the bar with gaps

BAR_HEIGHT=45 # 40px bar + 5px margin
GAP=20

is_floating=$(hyprctl activewindow -j | jq '.floating')

if [ "$is_floating" = "true" ]; then
  hyprctl dispatch togglefloating
  exit 0
fi

# Get active monitor dimensions and position
monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
monitor_json=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$monitor\")")

mon_w=$(echo "$monitor_json" | jq '.width')
mon_h=$(echo "$monitor_json" | jq '.height')
mon_x=$(echo "$monitor_json" | jq '.x')
mon_y=$(echo "$monitor_json" | jq '.y')
scale=$(echo "$monitor_json" | jq '.scale')

# Scale-adjusted monitor dimensions
scaled_w=$(awk "BEGIN { printf \"%d\", $mon_w / $scale }")
scaled_h=$(awk "BEGIN { printf \"%d\", $mon_h / $scale }")

# Usable area after bar and gaps
usable_w=$((scaled_w - GAP * 2))
usable_h=$((scaled_h - BAR_HEIGHT - GAP * 2))

# Fit 16:9 within usable area
fit_by_width_h=$((usable_w * 9 / 16))
fit_by_height_w=$((usable_h * 16 / 9))

if [ "$fit_by_width_h" -le "$usable_h" ]; then
  win_w=$usable_w
  win_h=$fit_by_width_h
else
  win_w=$fit_by_height_w
  win_h=$usable_h
fi

# Center within usable area
x=$((mon_x + (scaled_w - win_w) / 2))
y=$((mon_y + BAR_HEIGHT + GAP + (usable_h - win_h) / 2))

hyprctl --batch "dispatch togglefloating; dispatch resizewindowpixel exact ${win_w} ${win_h},activewindow; dispatch movewindowpixel exact ${x} ${y},activewindow"
