#!/bin/bash
name="$1"
branch="${2:-main}"
issue="$3"

repo_root=$(git rev-parse --show-toplevel)

git worktree add -b "$name" ".claude/worktrees/$name" "$branch"
cd ".claude/worktrees/$name"

prompt="You are in a git worktree on branch $name branched from $branch."

if [ -n "$issue" ]; then
  prompt="$prompt Use the linear MCP to fetch issue $issue and gather full context before starting work. All commit messages should reference the issue. e.g. 'fix: some fix (ABC-123)'"
else
  prompt="$prompt"
fi

# Escape for Lua string literal
lua_prompt=$(printf '%s' "$prompt" | sed 's/[\\]/\\\\&/g; s/"/\\"/g')

# Mark this pane as a worktree pane (for prefix-x cleanup)
pane_id=$(tmux display-message -p '#{pane_id}')
mkdir -p /tmp/tmux_worktrees
echo "$name|$repo_root" > "/tmp/tmux_worktrees/$pane_id"

$HOME/.local/share/bob/nvim-bin/nvim . -c "lua vim.defer_fn(function() vim.cmd([[Sidekick cli send msg=\"$lua_prompt\" submit=true name=claude]]) end, 100)"

$SHELL

# Normal exit: remove marker and prompt inline
rm -f "/tmp/tmux_worktrees/$pane_id"

if gum confirm "Delete worktree '$name'?"; then
  cd "$repo_root"
  git worktree remove ".claude/worktrees/$name" --force
  git branch -d "$name" 2>/dev/null
fi
