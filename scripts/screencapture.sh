#!/bin/bash

arg="$1"

# Check if wf-recorder is already running, if so kill it and exit
pgrep -x "wf-recorder" && pkill -INT -x wf-recorder && exit 0

IMG_FOLDER="${HOME}/Pictures/Screenshots"

IMG="${IMG_FOLDER}/$(date +%Y-%m-%d_%H-%M-%S).png"

VID_FOLDER="${HOME}/Videos/Screencaptures"

VID="${VID_FOLDER}/$(date +%Y-%m-%d_%H-%M-%S).mp4"

get_active_monitor() {
  hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

# type is img or vid
notify_with_open_folder() {
  output=$(notify-send "$1" --action "open-folder=Open folder" -t 5000 --app-name "$(basename "$0")")
  if [[ "$output" == "open-folder" ]]; then
    [[ "$2" == "img" ]] && nautilus "$IMG_FOLDER"
    [[ "$2" == "vid" ]] && nautilus "$VID_FOLDER"
  fi
}

grain_shader_on() {
  hyprshade on grain
}

grain_shader_off() {
  hyprshade off
}


case "$arg" in
select-shot)
  grain_shader_off
  region=$(slurp -d)
  if [ $? -eq 0 ]; then
    grim -g "$region" - | tee "$IMG" | wl-copy && grain_shader_on && notify_with_open_folder "Successfully took screenshot" "img"
  fi
  ;;
screen-shot)
  grain_shader_off
  grim - | tee "$IMG" | wl-copy && grain_shader_on && notify_with_open_folder "Successfully took screenshot" "img"
  ;;
record-screen)
  grain_shader_off
  wf-recorder -f "$VID" -o $(get_active_monitor) >/dev/null 2>&1 && grain_shader_on && notify_with_open_folder "Successfully recorded screen" "vid"
  ;;
select-record-screen)
  grain_shader_off
  region=$(slurp -d)
  if [ $? -eq 0 ]; then
    wf-recorder -g "$region" -f "$VID" -o $(get_active_monitor) >/dev/null 2>&1 && grain_shader_on && notify_with_open_folder "Successfully recorded screen" "vid"
  fi
  ;;
esac
