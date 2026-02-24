#!/bin/bash
# ~/scripts/tmux_worktree_prompt.sh

# 1. Linear issue ID (optional — just hit enter to skip)
issue=$(gum input --no-show-help --placeholder '(optional) Linear issue ID...' --prompt '❯ ' --prompt.foreground '#c9a554') || exit 0

# 2. If issue provided, derive branch name from Linear URL
suggested_name=""
if [ -n "$issue" ]; then
  url=$(linear issue url "$issue" 2>/dev/null)
  if [ -n "$url" ]; then
    slug=$(echo "$url" | awk -F'/' '{print tolower($NF)}')
    suggested_name="feature/${issue,,}-${slug}"
  fi
fi

# 3. Worktree name (prefilled if we got a suggestion, blank otherwise)
name=$(gum input --no-show-help --value "$suggested_name" --placeholder 'Worktree name...' --prompt '❯ ' --prompt.foreground '#c9a554') || exit 0
[ -z "$name" ] && exit 0

# 4. Base branch (optional)
branch=$(gum input --no-show-help --placeholder '(optional) base branch...' --prompt '❯ ' --prompt.foreground '#c9a554') || branch=""

tmux new-window -n "$name" "$HOME/scripts/tmux_worktree.sh" "$name" "$branch" "$issue"
