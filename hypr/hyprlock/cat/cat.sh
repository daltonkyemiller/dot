#!/bin/bash

display_frame() {
  local text=("$@")
  local rows=${#text[@]}
  local cols=${#text[0]}
  local start_row=0
  local start_col=0

  clear

  for ((i = 0; i < rows; i++)); do
    tput cup $((start_row + i)) $start_col
    echo -e "${text[$i]}"
  done
  sleep 0.3
}

animation_name=$(cat animation_name)
cd $animation_name/

frames=$(cat frameList)

while true; do
  for frame in $frames; do
    frameText=()
    while IFS= read -r line; do
      frameText+=("$line")
    done <"$frame"

    display_frame "${frameText[@]}"
  done
done
