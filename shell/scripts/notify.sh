#!/bin/bash

generate_line_numbers() {
    echo $(fakedata int:1,5 -l 1)
}

generate_random_expire_time() {
    echo $(fakedata int:8000,15000 -l 1)
}
generate_random_sleep_time() {
    echo $(fakedata int:2,5 -l 1)
}

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\nScript terminated"; exit 0' SIGINT

# Run the command in a loop
while true; do
    EXPIRE_TIME=$(generate_random_expire_time)
    notify-send --app-name "$(fakedata industry -l 1)" --expire-time "$EXPIRE_TIME" --action "Dismiss" "$(fakedata sentence -l 1)" "$(fakedata sentence -l "$(generate_line_numbers)")"

    sleep $(generate_random_sleep_time)
done
