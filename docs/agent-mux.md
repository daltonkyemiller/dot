# Agent Mux

`agent-mux` is the tmux-native workflow for running multiple Claude/OpenCode sessions with visibility and quick switching.

It does four jobs:

1. Tracks agent status by pane.
2. Opens a persistent side panel for an agent session.
3. Lets you jump between agents from a picker.
4. Routes key-driven actions to the correct parent tmux client.

## Keybindings

Defined in `.tmux.conf`.

- `Alt-c`: toggle the selected agent side panel for the current working directory.
- `Alt-o`: open the session picker for current working directory (existing sessions + new session actions).
- `Alt-a`: open global agent picker (jump to tracked agents).
- `Alt-@`: send a literal `@` to the pane.
- `@`: open file picker for agent panes and insert `@path` tokens.
- `prefix + e`: open sesh picker routed to the correct tmux client.

## Session Model

### Parent pane

Normal tmux pane where you are working.

### Agent side pane

A split pane that runs:

```bash
TMUX= tmux attach-session -t <agent-session>
```

This attaches a dedicated agent tmux session inside the split pane.

### Agent session creation

When you pick `New Claude session` or `New OpenCode session`, `agent-mux` creates a detached tmux session with only the agent process:

- Claude: `claude --allow-dangerously-skip-permissions`
- OpenCode: `opencode`

The session status bar is disabled for cleaner nested rendering.

## Focus and Client Routing

Nested tmux clients make naive key handling flaky. Actions can apply to the wrong client if you run plain `switch-client` from the wrong context.

`agent-mux` handles this by:

- resolving owner pane metadata (`@agent_mux_view_owner`, `@agent_mux_view_session`),
- opening pickers against the right client when invoked from side panes,
- storing deferred focus targets in state and applying focus after popup exit,
- switching to session + window + pane in that order.

This is what prevents loops and wrong-context jumps when `Alt-a` or `prefix + e` are triggered inside an agent side pane.

## State Files

All runtime state lives under:

```text
~/.local/state/agent-mux
```

### Agent status per pane

```text
~/.local/state/agent-mux/<pane-id-without-%>.json
```

Contains tool, status, prompt preview, and tmux location metadata.

### Panel selection per owner pane

```text
~/.local/state/agent-mux/panels/<owner-pane-id-without-%>.json
```

Maps owner pane + cwd to selected agent session.

### Deferred focus target

```text
~/.local/state/agent-mux/focus-<client-tty>.json
```

Used to apply pane focus after popup exit.

### Neovim picker context per cwd

```text
~/.local/state/agent-mux/nvim-context/<cwd-sha256-prefix>.json
```

Written by Neovim autocmds. Used by `tmux-file-picker.sh` to rank relevant files first.

## File Picker Behavior

`scripts/tmux-file-picker.sh` powers `@` in agent-aware panes.

Features:

- nonicons glyphs (mapped to Ghostty nonicons codepoint range),
- colored file icons,
- dim directory path + brighter basename,
- top preview with `bat`,
- multi-select to inject `@path` tokens,
- smart ranking from Neovim context (current file, alternate file, open buffers, recent files).

When picker is opened from a side pane, insertion is sent to the underlying agent process pane, not the nested `tmux` attach pane.

## Neovim Integration

Neovim writes cwd-scoped context from `nvim/lua/config/autocmds.lua`.

Autocmd triggers:

- `VimEnter`
- `BufEnter`
- `WinEnter`
- `BufWritePost`
- `DirChanged`

Payload includes:

- `current_file`
- `alternate_file`
- `open_buffers`
- `recent_files`
- `cwd`
- `tmux_pane`
- `updated_at`

## Main Scripts

- `scripts/agent-mux`: core session/panel/focus routing logic.
- `scripts/tmux-file-picker.sh`: `@` picker + insertion logic.
- `scripts/tmux-sesh-picker.sh`: sesh picker wrapped to switch the correct tmux client.

## Troubleshooting

If behavior gets weird after tmux crashes or manual session kills:

```bash
~/scripts/agent-mux cleanup
```

Then reload tmux config:

```bash
tmux source-file ~/.tmux.conf
```
