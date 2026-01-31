#!/bin/bash
# Claude response history manager
# Usage as hook: receives JSON with transcript_path on stdin
# Usage manual: --copy {idx} to copy response to clipboard
#               --debug {path} to enable logging

set -o pipefail

RESPONSES_FILE=~/.claude/hooks/responses.jsonl
MAX_RESPONSES=10

log() {
    [[ -n "$DEBUG_LOG" ]] && echo "$1" >> "$DEBUG_LOG"
}

get_clipboard_cmd() {
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        command -v wl-copy &>/dev/null && echo "wl-copy" && return
    fi
    if [[ -n "$DISPLAY" ]]; then
        command -v xclip &>/dev/null && echo "xclip -selection clipboard" && return
        command -v xsel &>/dev/null && echo "xsel --clipboard --input" && return
    fi
    command -v pbcopy &>/dev/null && echo "pbcopy" && return
    echo ""
}

copy_to_clipboard() {
    local text="$1"
    local cmd
    cmd=$(get_clipboard_cmd)
    if [[ -z "$cmd" ]]; then
        echo "Error: No clipboard tool found (tried wl-copy, xclip, xsel, pbcopy)" >&2
        return 1
    fi
    echo -n "$text" | $cmd
}

save_response() {
    local response="$1"
    local timestamp
    timestamp=$(date -Iseconds)

    mkdir -p "$(dirname "$RESPONSES_FILE")"

    # Append new response
    jq -nc --arg ts "$timestamp" --arg resp "$response" '{timestamp: $ts, response: $resp}' >> "$RESPONSES_FILE"

    # Keep only last MAX_RESPONSES
    if [[ -f "$RESPONSES_FILE" ]]; then
        local count
        count=$(wc -l < "$RESPONSES_FILE")
        if (( count > MAX_RESPONSES )); then
            local tmp
            tmp=$(mktemp)
            tail -n "$MAX_RESPONSES" "$RESPONSES_FILE" > "$tmp" && mv "$tmp" "$RESPONSES_FILE"
        fi
    fi
}

get_response_by_idx() {
    local idx="$1"
    if [[ ! -f "$RESPONSES_FILE" ]]; then
        echo "Error: No saved responses found" >&2
        return 1
    fi
    local response
    response=$(tail -n "$idx" "$RESPONSES_FILE" | head -n 1 | jq -r '.response')
    if [[ -z "$response" || "$response" == "null" ]]; then
        echo "Error: Response at index $idx not found" >&2
        return 1
    fi
    echo "$response"
}

# Parse arguments
DEBUG_LOG=""
COPY_IDX=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            DEBUG_LOG="$2"
            shift 2
            ;;
        --copy)
            COPY_IDX="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Handle --copy mode
if [[ -n "$COPY_IDX" ]]; then
    response=$(get_response_by_idx "$COPY_IDX")
    if [[ $? -eq 0 ]]; then
        copy_to_clipboard "$response"
        echo "Copied response $COPY_IDX to clipboard"
    fi
    exit $?
fi

# Normal hook mode - read from stdin
log "=== Hook called at $(date) ==="

input=$(cat)
transcript=$(echo "$input" | jq -r '.transcript_path' 2>/dev/null)

if [[ -z "$transcript" || "$transcript" == "null" || ! -f "$transcript" ]]; then
    log "Error: Invalid or missing transcript path: $transcript"
    exit 0  # Exit cleanly so hook doesn't show error
fi

log "Transcript path: $transcript"

# Extract last assistant message from JSONL transcript
last_response=$(tac "$transcript" 2>/dev/null | while read -r line; do
    type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
    if [[ "$type" == "assistant" ]]; then
        echo "$line" | jq -r '.message.content[] | select(.type == "text") | .text' 2>/dev/null
        break
    fi
done)

log "Extracted response: $last_response"

# Save response to history
if [[ -n "$last_response" ]]; then
    save_response "$last_response"
fi

log "=== Hook finished ==="
exit 0
