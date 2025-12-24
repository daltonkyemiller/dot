#!/bin/bash

TOUCHPAD="apple-mtp-multi-touch"
TIMEOUT=1
LAST_KEY=0

libinput debug-events --device /dev/input/event3 2>/dev/null | while read line; do
    if [[ "$line" == *"KEYBOARD_KEY"* && "$line" == *"pressed"* ]]; then
        hyprctl keyword "device[$TOUCHPAD]:enabled" false > /dev/null 2>&1
        
        # Reset timer in background
        (
            sleep $TIMEOUT
            hyprctl keyword "device[$TOUCHPAD]:enabled" true > /dev/null 2>&1
        ) &
    fi
done
