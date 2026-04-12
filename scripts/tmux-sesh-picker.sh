#!/usr/bin/env bash
set -euo pipefail

CLIENT_TTY="${1:-}"
[[ -z "$CLIENT_TTY" ]] && { echo "Usage: $0 <client-tty>" >&2; exit 1; }

selected=$(
  sesh list --icons | fzf-tmux -p 80%,70% \
    --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find ^y copy path' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
    --bind 'ctrl-y:execute-silent(sesh-copy-path {2..})+abort' \
    --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
    --preview-window 'right:55%' \
    --preview 'sesh preview {}'
) || exit 0

clean=$(printf '%s\n' "$selected" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
target="$clean"
if [[ "$clean" =~ ^[^[:alnum:]/.~_-][[:space:]]+(.+)$ ]]; then
  target="${BASH_REMATCH[1]}"
fi
target="${target#${target%%[![:space:]]*}}"
target="${target%${target##*[![:space:]]}}"
[[ -n "$target" ]] || exit 0

if tmux has-session -t "$target" 2>/dev/null; then
  tmux switch-client -c "$CLIENT_TTY" -t "$target"
  exit 0
fi

target_dir="$target"
if [[ "$target_dir" == ~* ]]; then
  target_dir="$HOME${target_dir#\~}"
fi

if [[ -d "$target_dir" ]]; then
  session_name="$target"
  if [[ "$target_dir" == "$HOME"/* ]]; then
    session_name="${target_dir#"$HOME"/}"
  fi

  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux switch-client -c "$CLIENT_TTY" -t "$session_name"
    exit 0
  fi

  tmux new-session -Ad -s "$session_name" -c "$target_dir"
  tmux switch-client -c "$CLIENT_TTY" -t "$session_name"
  exit 0
fi

sesh connect --switch "$target" 2>/dev/null || sesh connect "$target" 2>/dev/null || true
if tmux has-session -t "$target" 2>/dev/null; then
  tmux switch-client -c "$CLIENT_TTY" -t "$target"
fi
