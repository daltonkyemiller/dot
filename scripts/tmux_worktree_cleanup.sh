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
  "gum confirm 'Delete worktree \"$name\"?' && cd '$repo_root' && git worktree remove '.claude/worktrees/$name' --force && git branch -d '$name' 2>/dev/null; true"

tmux display-popup -E -w 60 -h 5 -b rounded -S "fg=#5f875f" -T " 🌳 Switch: $display_name " \
  "gum confirm 'Switch to $name?' && cd '$repo_root' && git checkout '$name'; true"
