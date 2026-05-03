---
name: claude-code-delegate
description: Delegate frontend implementation, UI design, visual polish, or plan-writing work to Claude Code through a tmux-hosted interactive TUI. Use when the user asks Codex to involve Claude Code, CC, or another frontend-focused coding agent; when frontend design judgment should be borrowed from Claude Code; or when Claude Code should produce a detailed Markdown plan for Codex to execute.
---

# Claude Code Delegate

Use Claude Code as a collaborator by running it inside tmux and controlling it with `tmux send-keys` / paste buffers. Claude Code is interactive, so do not expect ordinary stdin/stdout automation to work reliably.

## Core Workflow

1. Decide whether Claude Code should implement or plan:
   - **Implement** when the user wants frontend design, visual refinement, layout, or UI code changes.
   - **Plan** when the user wants Claude Code to think through an approach for Codex to execute later.

2. Gather enough local context before prompting Claude:
   - User request and exact success criteria.
   - Current working directory and relevant routes/components/files.
   - Existing design system, styling stack, package manager, and dev/test commands when discoverable.
   - Constraints from `AGENTS.md`, shared instructions, and relevant skills.
   - Current dirty-worktree facts that Claude must preserve.

3. Write a prompt file, preferably outside the repo:
   ```bash
   mkdir -p "${CLAUDE_CODE_DELEGATE_DIR:-$HOME/.cache/claude-code-delegate}"
   $EDITOR "$HOME/.cache/claude-code-delegate/<task-slug>-prompt.md"
   ```

4. Start Claude Code in tmux:
   ```bash
   .agents/skills/claude-code-delegate/scripts/cc-delegate.sh start <session-name> <worktree>
   ```

5. Send the prompt file:
   ```bash
   .agents/skills/claude-code-delegate/scripts/cc-delegate.sh send <session-name> <prompt-file>
   ```

6. Observe progress:
   ```bash
   .agents/skills/claude-code-delegate/scripts/cc-delegate.sh capture <session-name>
   tmux attach -t <session-name>
   ```

7. Integrate results:
   - For implementation, inspect Claude's diff before continuing.
   - For planning, read the Markdown plan Claude wrote and decide what to execute locally.
   - Validate with the appropriate tests, build, screenshots, or browser checks yourself. Do not treat Claude's completion as verification.

## Prompt Requirements

Give Claude Code a complete handoff. Include:

```markdown
# Task
<What Claude should accomplish.>

# Mode
Implement directly in this worktree.
OR
Create a detailed Markdown plan only.

# Repo
- Worktree: /absolute/path
- Package manager/runtime:
- Relevant commands:
- Relevant files/routes:

# Context
<Concise but specific findings from Codex's repo inspection.>

# Constraints
- Follow the repo's AGENTS.md and shared instructions.
- Preserve unrelated user changes. Do not revert files you did not need to touch.
- Do not commit unless explicitly asked.
- Prefer existing patterns/components/tokens over new abstractions.
- For frontend work, prioritize visual quality, responsive behavior, and actual usability.

# Deliverable
- If implementing: edit files directly, then write a summary to <absolute-output-md>.
- If planning: write the full plan to <absolute-output-md>.
- Include changed files, commands run, remaining risks, and anything Codex should verify.
```

Use an absolute output path under `${CLAUDE_CODE_DELEGATE_DIR:-$HOME/.cache/claude-code-delegate}` unless the user asked for a repo-local artifact.

## Frontend Delegation

Claude Code is most useful here for frontend taste and layout judgment. Ask for concrete work, not vague polish:

- Name the screen, component, route, and viewport requirements.
- Provide screenshots or Figma/design context when available.
- State which parts of the design are fixed and which are open to reinterpretation.
- Ask Claude to keep controls complete and production-ready, not just visually plausible.
- Ask Claude to avoid broad refactors unless required for the visible result.

After Claude finishes, run your own review against the repo's frontend guidance and use browser/screenshot checks when the change affects visible UI.

## Planning Delegation

When Claude should plan for Codex:

- Tell Claude not to edit code.
- Ask for a step-by-step plan with file paths, implementation sequence, testing strategy, and edge cases.
- Require the plan to be saved to an absolute Markdown path.
- Read the plan before acting; keep or discard recommendations based on repo truth.

## Tmux Notes

- Start command: `CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions`.
- Use paste buffers for prompts instead of typing long text through `send-keys`.
- Keep session names short and task-specific, such as `cc-homepage-polish`.
- If the TUI is waiting for confirmation, inspect with `capture` or attach with tmux, then send the needed keys with:
  ```bash
  tmux send-keys -t <session-name>:0.0 Enter
  ```
- Stop a finished session with:
  ```bash
  .agents/skills/claude-code-delegate/scripts/cc-delegate.sh stop <session-name>
  ```
