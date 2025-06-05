#!/bin/bash

# Check if a command was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <command>"
    exit 1
fi

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\nScript terminated"; exit 0' SIGINT

# Run the command in a loop
while true; do
    "$@"
    sleep 5
done
