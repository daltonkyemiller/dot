#!/bin/bash
# ~/scripts/tmux_worktree_prompt.sh

# 0. Check for reopenable branches (exist locally, not in a worktree already)
worktree_branches=$(git worktree list --porcelain | grep '^branch' | sed 's|branch refs/heads/||')
reopenable=$(git branch --format='%(refname:short)' | grep -vxFf <(echo "$worktree_branches"))

if [ -n "$reopenable" ]; then
  choice=$(printf "%s\n%s" "✨ New worktree" "$reopenable" | \
    gum filter --no-show-help --height 10 --placeholder 'Select branch or create new...' --prompt '❯ ' --prompt.foreground '#c9a554') || exit 0

  if [ "$choice" != "✨ New worktree" ]; then
    ai=$(printf "claude\nopencode" | gum filter --no-show-help --height 4 --placeholder 'AI tool...' --prompt '❯ ' --prompt.foreground '#c9a554') || ai="claude"
    tmux new-window -n "$choice" "$HOME/scripts/tmux_worktree.sh" "$choice" "" "" "$ai"
    exit 0
  fi
fi

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

# 5. AI tool
ai=$(printf "claude\nopencode" | gum filter --no-show-help --height 4 --placeholder 'AI tool...' --prompt '❯ ' --prompt.foreground '#c9a554') || ai="claude"

tmux new-window -n "$name" "$HOME/scripts/tmux_worktree.sh" "$name" "$branch" "$issue" "$ai"
