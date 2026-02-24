#!/bin/bash
name="$1"
branch="${2:-main}"
issue="$3"

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

$HOME/.local/share/bob/nvim-bin/nvim . -c "lua vim.defer_fn(function() vim.cmd([[Sidekick cli send msg=\"$lua_prompt\" submit=true name=claude]]) end, 100)"

exec $SHELL
