#!/bin/bash

set -euo pipefail

# Portal passes these arguments
multiple="$1"    # 0 or 1 for multiple selection
directory="$2"   # 0 or 1 for directory mode
save="$3"        # 0 or 1 for save dialog
path="$4"        # starting path
out="$5"         # output file to write selection
# $6 is an additional portal argument (unused)

if [[ "$save" == "1" ]]; then
    ghostty --title="file-chooser" -e yazi --chooser-file="$out" "$path"
else
    if [[ "$directory" == "1" ]]; then
        ghostty --title="file-chooser" -e yazi --chooser-file="$out" --cwd-file="$out" "$path"
    else
        ghostty --title="file-chooser" -e yazi --chooser-file="$out" "$path"
    fi
fi

# Post-process: fix search:// URLs from yazi search mode
if [[ -f "$out" ]]; then
    content=$(cat "$out")
    # Extract real path from search://term:line:col//path format
    if [[ "$content" =~ ^search://[^/]+//(.+)$ ]]; then
        real_path="/${BASH_REMATCH[1]}"
        # URL decode
        real_path=$(printf '%b' "${real_path//%/\\x}")
        echo "$real_path" > "$out"
    fi
fi
