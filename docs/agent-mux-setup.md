# agent-mux Setup

Tracks AI agent instances across tmux panes with status notifications and a picker to jump between them.

## Components

- `scripts/agent-mux` — Main script (stowed to `~/scripts/agent-mux`)
- `shell/services/AgentMux.qml` — Quickshell service (watches trigger file)
- `shell/widgets/AgentOsd.qml` — Quickshell OSD widget (in-terminal notification)
- `.tmux.conf` — `prefix + g` keybinding for the agent picker

## Dependencies

- `jq`, `fzf`, `notify-send`, `tmux`, `hyprctl`
- Quickshell (for in-terminal OSD)

## Claude Code Hooks

Add the following hooks to `~/.claude/settings.json` under the `"hooks"` key:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/dalton/dev/dot/scripts/agent-mux update claude idle"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/dalton/dev/dot/scripts/agent-mux update claude working"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/dalton/dev/dot/scripts/agent-mux update claude idle"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/dalton/dev/dot/scripts/agent-mux remove"
          }
        ]
      }
    ]
  }
}
```

### What the hooks do

| Hook | Event | Effect |
|------|-------|--------|
| `SessionStart` | Claude session launches | Registers agent as **idle** (visible in picker immediately) |
| `UserPromptSubmit` | User sends a prompt | Marks agent as **working**, captures prompt preview |
| `Stop` | Claude finishes a turn | Marks agent as **idle**, sends notification |
| `SessionEnd` | Claude session exits | Removes agent state file |

## How notifications work

When an agent goes idle and the user isn't focused on its pane:

- **Ghostty is focused** — Writes to `~/.local/state/agent-mux/osd-trigger`, Quickshell shows an OSD overlay on the top-right of the Ghostty window
- **Ghostty is not focused** — Sends a `notify-send` desktop notification

## State

Agent state files live in `~/.local/state/agent-mux/` as JSON files keyed by tmux pane ID. The OSD trigger file is `~/.local/state/agent-mux/osd-trigger`.

## Tmux keybinding

`prefix + g` opens an fzf picker showing all tracked agents with status, tool, location, and prompt preview. Selecting one switches to that pane (or the parent Neovim pane for sidekick sessions).
