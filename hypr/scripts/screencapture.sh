#!/bin/bash

arg="$1"

# Check if wf-recorder is already running, if so kill it and exit
pgrep -x "wf-recorder" && pkill -INT -x wf-recorder && exit 0

IMG="${HOME}/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"

VID_FOLDER="${HOME}/Videos/Screencaptures"

VID="${VID_FOLDER}/$(date +%Y-%m-%d_%H-%M-%S).mp4"

get_active_monitor() {
  hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

case "$arg" in
select-shot)
  grim -g "$(slurp -d)" - | tee "$IMG" | wl-copy
  ;;
screen-shot)
  grim - | tee "$IMG" | wl-copy
  ;;
record-screen)
  output=$(wf-recorder -f "$VID" -o $(get_active_monitor) >/dev/null 2>&1 && notify-send "Successfully recorded screen" --action "open-folder=Open folder" -t 5000)
  if [[ "$output" == "open-folder" ]]; then
    nautilus "$VID_FOLDER"
  fi
  ;;
select-record-screen)
  output=$(wf-recorder -g "$(slurp -d)" -f "$VID" -o $(get_active_monitor) >/dev/null 2>&1 && notify-send "Successfully recorded screen" --action "open-folder=Open folder" -t 5000)
  if [[ "$output" == "open-folder" ]]; then
    nautilus "$VID_FOLDER"
  fi
  ;;
esac
