#!/bin/bash
# Called by prefix-x binding when a worktree pane is killed
pane_id="$1"
info_file="/tmp/tmux_worktrees/$pane_id"

IFS='|' read -r name repo_root < "$info_file"
rm "$info_file"

tmux kill-pane -t "$pane_id"

display_name="${name:0:30}"
[ "${#name}" -gt 30 ] && display_name="${display_name}…"

tmux display-popup -E -w 60 -h 5 -b rounded -S "fg=#5f875f" -T " 🌳 Cleanup: $display_name " \
  "if gum confirm 'Delete worktree \"$name\"?'; then cd '$repo_root' && git worktree remove '.worktrees/$name' --force; fi" 2>/dev/null

# Only offer branch switch if worktree was deleted (branch is free)
if ! git -C "$repo_root" worktree list | grep -q "\\[$name\\]"; then
  tmux display-popup -E -w 60 -h 5 -b rounded -S "fg=#5f875f" -T " 🌳 Switch: $display_name " \
    "gum confirm 'Switch to $name?' && cd '$repo_root' && git checkout '$name'; true"
fi
