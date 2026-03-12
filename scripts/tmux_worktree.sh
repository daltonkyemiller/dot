#!/bin/bash
name="$1"
branch="${2:-main}"
issue="$3"
ai="${4:-claude}"

repo_root=$(git rev-parse --show-toplevel)

# Reuse existing branch or create a new one
if git show-ref --verify --quiet "refs/heads/$name"; then
  git worktree add ".worktrees/$name" "$name"
else
  git worktree add -b "$name" ".worktrees/$name" "$branch"
fi
cd ".worktrees/$name"

prompt="You are in a git worktree on branch $name branched from $branch."

if [ -n "$issue" ]; then
  prompt="$prompt Use the linear MCP to fetch issue $issue and gather full context before starting work. All commit messages should reference the issue. e.g. 'fix: some fix (ABC-123)'"
fi

# Escape for Lua string literal
lua_prompt=$(printf '%s' "$prompt" | sed 's/[\\]/\\\\&/g; s/"/\\"/g')

# Mark this pane as a worktree pane (for prefix-x cleanup)
pane_id=$(tmux display-message -p '#{pane_id}')
mkdir -p /tmp/tmux_worktrees
echo "$name|$repo_root" > "/tmp/tmux_worktrees/$pane_id"

$HOME/.local/share/bob/nvim-bin/nvim . -c "lua vim.defer_fn(function() vim.cmd([[Sidekick cli send msg=\"$lua_prompt\" submit=true name=$ai]]) end, 100)"

$SHELL

# Normal exit: remove marker and prompt inline
rm -f "/tmp/tmux_worktrees/$pane_id"

if gum confirm "Delete worktree '$name'?"; then
  cd "$repo_root"
  git worktree remove ".worktrees/$name" --force

  if gum confirm "Switch to '$name'?"; then
    git checkout "$name"
  fi
fi
