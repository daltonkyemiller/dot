#!/usr/bin/env bash
set -euo pipefail

CLAUDE_COMMAND="${CLAUDE_CODE_COMMAND:-CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions}"
DEFAULT_CAPTURE_LINES="${CLAUDE_CODE_CAPTURE_LINES:-240}"

usage() {
  cat >&2 <<'EOF'
Usage:
  cc-delegate.sh start <session-name> [workdir]
  cc-delegate.sh send <session-name> <prompt-file>
  cc-delegate.sh capture <session-name> [lines]
  cc-delegate.sh list
  cc-delegate.sh stop <session-name>

Examples:
  cc-delegate.sh start cc-homepage /path/to/repo
  cc-delegate.sh send cc-homepage /tmp/homepage-prompt.md
  cc-delegate.sh capture cc-homepage 300
  cc-delegate.sh stop cc-homepage
EOF
}

require_tmux() {
  command -v tmux >/dev/null 2>&1 || {
    echo "tmux is required" >&2
    exit 1
  }
}

require_session_name() {
  local session_name="${1:-}"
  if [[ -z "$session_name" ]]; then
    usage
    exit 1
  fi

  if [[ ! "$session_name" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "Session name may only contain letters, numbers, dots, underscores, and hyphens: $session_name" >&2
    exit 1
  fi
}

target_pane() {
  printf '%s:0.0' "$1"
}

start_session() {
  local session_name="$1"
  local workdir="${2:-$PWD}"

  require_session_name "$session_name"

  if [[ ! -d "$workdir" ]]; then
    echo "Workdir does not exist: $workdir" >&2
    exit 1
  fi

  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Session already exists: $session_name"
    echo "Attach with: tmux attach -t $session_name"
    return 0
  fi

  tmux new-session -d -s "$session_name" -c "$workdir" "$CLAUDE_COMMAND"
  tmux set-option -t "$session_name" remain-on-exit on >/dev/null

  echo "Started Claude Code tmux session: $session_name"
  echo "Workdir: $workdir"
  echo "Attach: tmux attach -t $session_name"
}

send_prompt() {
  local session_name="$1"
  local prompt_file="${2:-}"
  local buffer_name

  require_session_name "$session_name"

  if [[ -z "$prompt_file" || ! -f "$prompt_file" ]]; then
    echo "Prompt file does not exist: ${prompt_file:-}" >&2
    exit 1
  fi

  tmux has-session -t "$session_name" 2>/dev/null || {
    echo "Session does not exist: $session_name" >&2
    exit 1
  }

  buffer_name="cc_delegate_${session_name}_$$"
  tmux load-buffer -b "$buffer_name" "$prompt_file"
  tmux paste-buffer -d -b "$buffer_name" -t "$(target_pane "$session_name")"
  tmux send-keys -t "$(target_pane "$session_name")" Enter

  echo "Sent prompt to Claude Code session: $session_name"
}

capture_session() {
  local session_name="$1"
  local lines="${2:-$DEFAULT_CAPTURE_LINES}"

  require_session_name "$session_name"

  if [[ ! "$lines" =~ ^[0-9]+$ ]]; then
    echo "Lines must be a positive integer: $lines" >&2
    exit 1
  fi

  tmux capture-pane -p -S "-$lines" -t "$(target_pane "$session_name")"
}

list_sessions() {
  tmux list-sessions -F '#S' 2>/dev/null | grep -E '(^cc-|claude|Claude)' || true
}

stop_session() {
  local session_name="$1"

  require_session_name "$session_name"
  tmux kill-session -t "$session_name"
  echo "Stopped Claude Code tmux session: $session_name"
}

main() {
  require_tmux

  local command="${1:-}"
  shift || true

  case "$command" in
    start)
      start_session "${1:-}" "${2:-$PWD}"
      ;;
    send)
      send_prompt "${1:-}" "${2:-}"
      ;;
    capture)
      capture_session "${1:-}" "${2:-$DEFAULT_CAPTURE_LINES}"
      ;;
    list)
      list_sessions
      ;;
    stop)
      stop_session "${1:-}"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "Unknown command: $command" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
