#!/usr/bin/env bash
# Symlinks each skill directory from this repo into ~/.claude/skills/ and ~/.agents/skills/
# Run after adding new skills or on a fresh machine.

set -euo pipefail

SKILL_SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DEST="$HOME/.claude/skills"
AGENTS_DEST="$HOME/.agents/skills"

mkdir -p "$CLAUDE_DEST" "$AGENTS_DEST"

linked=0
skipped=0

inc() { eval "$1=\$(( $1 + 1 ))"; }

for skill_dir in "$SKILL_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"

  # Skip self (this script lives alongside skill dirs)
  [ -f "$skill_dir/SKILL.md" ] || continue

  for dest in "$CLAUDE_DEST" "$AGENTS_DEST"; do
    target="$dest/$skill_name"

    if [ -L "$target" ]; then
      existing="$(readlink -f "$target")"
      expected="$(readlink -f "$skill_dir")"
      if [ "$existing" = "$expected" ]; then
        inc skipped
        continue
      fi
      # Points somewhere else — replace it
      rm "$target"
    elif [ -e "$target" ]; then
      echo "WARN: $target exists and is not a symlink, skipping"
      inc skipped
      continue
    fi

    ln -s "$skill_dir" "$target"
    echo "  $skill_name -> $dest/"
    inc linked
  done
done

echo ""
echo "Done. $linked linked, $skipped already up to date."
