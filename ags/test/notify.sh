#!/bin/bash

generate_line_numbers() {
    echo $(fakedata int:1,5 -l 1)
}

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\nScript terminated"; exit 0' SIGINT

# Run the command in a loop
while true; do
    notify-send "$(fakedata sentence -l "$(generate_line_numbers)")" --app-name "$(fakedata industry -l 1)"
    sleep 5
done
