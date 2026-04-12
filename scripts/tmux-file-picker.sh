#!/usr/bin/env bash
# Tmux popup file picker for AI CLIs (claude, opencode, etc).
# Shows a preview on top and a fuzzy file list on bottom.
# On confirm, sends "@<relative-path>" to the target pane.
#
# Usage: tmux-file-picker.sh <target-pane-id>
set -euo pipefail

TARGET_PANE="${1:-}"
if [[ -z "$TARGET_PANE" ]]; then
  echo "Usage: $0 <target-pane-id>" >&2
  exit 1
fi

SEND_PANE="$TARGET_PANE"
VIEW_SESSION=$(tmux show-options -p -t "$TARGET_PANE" -qv @agent_mux_view_session 2>/dev/null || true)
if [[ -n "$VIEW_SESSION" ]]; then
  SOURCE_PANE=$(tmux list-panes -t "$VIEW_SESSION" -F '#{pane_id} #{pane_current_command}' 2>/dev/null \
    | awk '$2 != "tmux" { print $1; exit }')
  if [[ -z "$SOURCE_PANE" ]]; then
    SOURCE_PANE=$(tmux list-panes -t "$VIEW_SESSION" -F '#{pane_id}' 2>/dev/null | awk 'NR==1 {print; exit}')
  fi
  [[ -n "$SOURCE_PANE" ]] && SEND_PANE="$SOURCE_PANE"
fi

# Resolve the target pane's current directory so paths are relative to it.
TARGET_CWD=$(tmux display-message -p -t "$TARGET_PANE" '#{pane_current_path}' 2>/dev/null || pwd)
[[ -n "$TARGET_CWD" ]] || TARGET_CWD="$HOME"
cd "$TARGET_CWD" 2>/dev/null || cd "$HOME"

JQ_BIN="$(command -v jq || true)"
SHA_BIN=""
if command -v sha256sum >/dev/null 2>&1; then
  SHA_BIN="$(command -v sha256sum)"
elif command -v shasum >/dev/null 2>&1; then
  SHA_BIN="$(command -v shasum)"
fi

# Resolve absolute binaries so fzf preview works even with minimal PATH.
BAT_BIN=""
if command -v bat >/dev/null 2>&1; then
  BAT_BIN="$(command -v bat)"
elif command -v batcat >/dev/null 2>&1; then
  BAT_BIN="$(command -v batcat)"
fi

if [[ -z "$BAT_BIN" ]]; then
  for candidate in \
    /usr/bin/bat \
    /usr/bin/batcat \
    /bin/bat \
    /bin/batcat \
    "$HOME/.local/bin/bat" \
    "$HOME/.local/bin/batcat"; do
    if [[ -x "$candidate" ]]; then
      BAT_BIN="$candidate"
      break
    fi
  done
fi

if [[ -z "$BAT_BIN" && -n "${SHELL:-}" ]]; then
  BAT_BIN=$("$SHELL" -lc 'command -v bat || command -v batcat' 2>/dev/null || true)
fi

if [[ -z "$BAT_BIN" ]]; then
  tmux display-message "bat not found for tmux-file-picker"
  exit 0
fi

AWK_BIN="$(command -v awk || true)"
if [[ -z "$AWK_BIN" ]]; then
  AWK_BIN="/usr/bin/awk"
fi

CUT_BIN="$(command -v cut || true)"
if [[ -z "$CUT_BIN" ]]; then
  CUT_BIN="/usr/bin/cut"
fi

FD_BIN="$(command -v fd || true)"
if [[ -z "$FD_BIN" ]]; then
  for candidate in /usr/bin/fd /usr/bin/fdfind /bin/fd /bin/fdfind "$HOME/.local/bin/fd"; do
    if [[ -x "$candidate" ]]; then
      FD_BIN="$candidate"
      break
    fi
  done
fi

if [[ -z "$FD_BIN" ]]; then
  tmux display-message "fd not found for tmux-file-picker"
  exit 0
fi

PREVIEW_CMD='path=$(printf "%s" {} | '"$CUT_BIN"' -f3-); '"$BAT_BIN"' --style=numbers --color=always --line-range=:300 -- "$path"'

CONTEXT_RANK_FILE=""
build_context_rank_file() {
  [[ -n "$JQ_BIN" && -n "$SHA_BIN" ]] || return 0

  local hash
  if [[ "$SHA_BIN" == *sha256sum ]]; then
    hash=$(printf '%s' "$TARGET_CWD" | "$SHA_BIN" | awk '{print $1}' | cut -c1-16)
  else
    hash=$(printf '%s' "$TARGET_CWD" | "$SHA_BIN" -a 256 | awk '{print $1}' | cut -c1-16)
  fi

  local context_file="${XDG_STATE_HOME:-$HOME/.local/state}/agent-mux/nvim-context/${hash}.json"
  [[ -f "$context_file" ]] || return 0

  if ! CONTEXT_RANK_FILE=$(mktemp 2>/dev/null); then
    CONTEXT_RANK_FILE="/tmp/tmux-file-picker-rank.$$.$RANDOM"
    : > "$CONTEXT_RANK_FILE"
  fi

  to_relative() {
    local path="$1"
    [[ -n "$path" && "$path" != "null" ]] || return
    if [[ "$path" == "$TARGET_CWD/"* ]]; then
      printf '%s\n' "${path#"$TARGET_CWD"/}"
    elif [[ "$path" != /* ]]; then
      printf '%s\n' "$path"
    fi
  }

  local value rel rank
  rank=1
  value=$("$JQ_BIN" -r '.current_file // empty' "$context_file" 2>/dev/null || true)
  rel=$(to_relative "$value")
  [[ -n "$rel" ]] && printf '%d\t%s\n' "$rank" "$rel" >> "$CONTEXT_RANK_FILE"

  rank=2
  value=$("$JQ_BIN" -r '.alternate_file // empty' "$context_file" 2>/dev/null || true)
  rel=$(to_relative "$value")
  [[ -n "$rel" ]] && printf '%d\t%s\n' "$rank" "$rel" >> "$CONTEXT_RANK_FILE"

  rank=10
  while IFS= read -r value; do
    rel=$(to_relative "$value")
    [[ -n "$rel" ]] && { printf '%d\t%s\n' "$rank" "$rel" >> "$CONTEXT_RANK_FILE"; rank=$((rank + 1)); }
  done < <("$JQ_BIN" -r '.open_buffers[]? // empty' "$context_file" 2>/dev/null || true)

  rank=100
  while IFS= read -r value; do
    rel=$(to_relative "$value")
    [[ -n "$rel" ]] && { printf '%d\t%s\n' "$rank" "$rel" >> "$CONTEXT_RANK_FILE"; rank=$((rank + 1)); }
  done < <("$JQ_BIN" -r '.recent_files[]? // empty' "$context_file" 2>/dev/null || true)

  if [[ -s "$CONTEXT_RANK_FILE" ]]; then
    local deduped
    deduped=$(mktemp 2>/dev/null || echo "/tmp/tmux-file-picker-rank-dedup.$$.$RANDOM")
    awk -F $'\t' '!seen[$2]++' "$CONTEXT_RANK_FILE" > "$deduped"
    mv "$deduped" "$CONTEXT_RANK_FILE"
  else
    rm -f "$CONTEXT_RANK_FILE"
    CONTEXT_RANK_FILE=""
  fi
}

format_candidates() {
  { "$FD_BIN" --type f --hidden --follow --exclude .git 2>/dev/null || true; } \
    | "$AWK_BIN" '
      function nonicon(name) {
        if (name == "c") return sprintf("%c", 61718)
        if (name == "c-plusplus") return sprintf("%c", 61719)
        if (name == "css") return sprintf("%c", 61743)
        if (name == "docker") return sprintf("%c", 61758)
        if (name == "file") return sprintf("%c", 61766)
        if (name == "git-branch") return sprintf("%c", 61783)
        if (name == "go") return sprintf("%c", 61789)
        if (name == "html") return sprintf("%c", 61799)
        if (name == "java") return sprintf("%c", 61809)
        if (name == "javascript") return sprintf("%c", 61810)
        if (name == "json") return sprintf("%c", 61811)
        if (name == "kotlin") return sprintf("%c", 61814)
        if (name == "lua") return sprintf("%c", 61826)
        if (name == "markdown") return sprintf("%c", 61829)
        if (name == "npm") return sprintf("%c", 61843)
        if (name == "python") return sprintf("%c", 61863)
        if (name == "ruby") return sprintf("%c", 61880)
        if (name == "rust") return sprintf("%c", 61881)
        if (name == "terminal") return sprintf("%c", 61911)
        if (name == "toml") return sprintf("%c", 61916)
        if (name == "typescript") return sprintf("%c", 61923)
        if (name == "yaml") return sprintf("%c", 61945)
        if (name == "tools") return sprintf("%c", 61917)
        return sprintf("%c", 61766)
      }

      function icon_for(path, base, ext, lower_base, lower_ext) {
        lower_base = tolower(base)
        ext = ""
        if (match(lower_base, /\.([^.]+)$/, m)) {
          ext = m[1]
        }
        lower_ext = tolower(ext)

        if (lower_base == "makefile" || lower_base == "gnumakefile") return nonicon("tools")
        if (lower_base == "dockerfile") return nonicon("docker")
        if (lower_base == "package.json" || lower_base == "package-lock.json" || lower_base == "pnpm-lock.yaml" || lower_base == "bun.lockb" || lower_base == "bun.lock") return nonicon("npm")
        if (lower_base == "tsconfig.json") return nonicon("typescript")
        if (lower_base == ".gitignore" || lower_base == ".gitattributes") return nonicon("git-branch")
        if (lower_base == ".env" || index(lower_base, ".env.") == 1) return nonicon("tools")
        if (lower_base == "readme" || index(lower_base, "readme.") == 1) return nonicon("markdown")

        if (lower_ext == "ts" || lower_ext == "tsx") return nonicon("typescript")
        if (lower_ext == "js" || lower_ext == "jsx" || lower_ext == "mjs" || lower_ext == "cjs") return nonicon("javascript")
        if (lower_ext == "json" || lower_ext == "jsonc") return nonicon("json")
        if (lower_ext == "lua") return nonicon("lua")
        if (lower_ext == "sh" || lower_ext == "bash" || lower_ext == "zsh" || lower_ext == "fish") return nonicon("terminal")
        if (lower_ext == "md" || lower_ext == "mdx") return nonicon("markdown")
        if (lower_ext == "yaml" || lower_ext == "yml") return nonicon("yaml")
        if (lower_ext == "toml") return nonicon("toml")
        if (lower_ext == "css" || lower_ext == "scss" || lower_ext == "sass" || lower_ext == "less") return nonicon("css")
        if (lower_ext == "html" || lower_ext == "htm") return nonicon("html")
        if (lower_ext == "go") return nonicon("go")
        if (lower_ext == "rs") return nonicon("rust")
        if (lower_ext == "py") return nonicon("python")
        if (lower_ext == "rb") return nonicon("ruby")
        if (lower_ext == "java") return nonicon("java")
        if (lower_ext == "kt" || lower_ext == "kts") return nonicon("kotlin")
        if (lower_ext == "c") return nonicon("c")
        if (lower_ext == "h" || lower_ext == "hpp" || lower_ext == "hh" || lower_ext == "hxx" || lower_ext == "cpp" || lower_ext == "cc" || lower_ext == "cxx") return nonicon("c-plusplus")

        return nonicon("file")
      }

      function color_for(path, base, ext, lower_base, lower_ext) {
        lower_base = tolower(base)
        ext = ""
        if (match(lower_base, /\.([^.]+)$/, m)) {
          ext = m[1]
        }
        lower_ext = tolower(ext)

        if (lower_base == "makefile" || lower_base == "gnumakefile") return "214"
        if (lower_base == "dockerfile") return "39"
        if (lower_base == "package.json" || lower_base == "package-lock.json" || lower_base == "pnpm-lock.yaml" || lower_base == "bun.lockb" || lower_base == "bun.lock") return "40"
        if (lower_base == "tsconfig.json") return "39"
        if (lower_base == ".gitignore" || lower_base == ".gitattributes") return "196"
        if (lower_base == ".env" || index(lower_base, ".env.") == 1) return "220"
        if (lower_base == "readme" || index(lower_base, "readme.") == 1) return "222"

        if (lower_ext == "ts" || lower_ext == "tsx") return "39"
        if (lower_ext == "js" || lower_ext == "jsx" || lower_ext == "mjs" || lower_ext == "cjs") return "220"
        if (lower_ext == "json" || lower_ext == "jsonc") return "214"
        if (lower_ext == "lua") return "39"
        if (lower_ext == "sh" || lower_ext == "bash" || lower_ext == "zsh" || lower_ext == "fish") return "114"
        if (lower_ext == "md" || lower_ext == "mdx") return "222"
        if (lower_ext == "yaml" || lower_ext == "yml") return "150"
        if (lower_ext == "toml") return "245"
        if (lower_ext == "css" || lower_ext == "scss" || lower_ext == "sass" || lower_ext == "less") return "81"
        if (lower_ext == "html" || lower_ext == "htm") return "203"
        if (lower_ext == "go") return "45"
        if (lower_ext == "rs") return "208"
        if (lower_ext == "py") return "220"
        if (lower_ext == "rb") return "203"
        if (lower_ext == "java") return "214"
        if (lower_ext == "kt" || lower_ext == "kts") return "99"
        if (lower_ext == "c") return "75"
        if (lower_ext == "h" || lower_ext == "hpp" || lower_ext == "hh" || lower_ext == "hxx" || lower_ext == "cpp" || lower_ext == "cc" || lower_ext == "cxx") return "75"

        return "245"
      }

      {
        path = $0
        count = split(path, parts, "/")
        base = parts[count]
        dir = ""
        for (i = 1; i < count; i++) {
          dir = dir parts[i] "/"
        }

        icon = icon_for(path, base)
        icon_color = "\033[38;5;" color_for(path, base) "m"
        dim = "\033[2;38;5;245m"
        reset = "\033[0m"
        if (dir != "") {
          display = icon_color icon reset " " dim dir reset base
        } else {
          display = icon_color icon reset " " base
        }

        printf "%s\t%s\n", display, path
      }
    '
}

# List files with fd (respects .gitignore, follows symlinks, includes hidden).
if ! CANDIDATE_FILE=$(mktemp 2>/dev/null); then
  CANDIDATE_FILE="/tmp/tmux-file-picker.$$.$RANDOM.candidates"
  : > "$CANDIDATE_FILE"
fi

if ! format_candidates > "$CANDIDATE_FILE"; then
  rm -f "$CANDIDATE_FILE"
  exit 0
fi

build_context_rank_file

RANKED_FILE=$(mktemp 2>/dev/null || echo "/tmp/tmux-file-picker-ranked.$$.$RANDOM")
if [[ -n "$CONTEXT_RANK_FILE" && -f "$CONTEXT_RANK_FILE" ]]; then
  if ! awk -F $'\t' -v rank_file="$CONTEXT_RANK_FILE" 'BEGIN {
        while ((getline < rank_file) > 0) {
          split($0, a, "\t")
          if (!(a[2] in rank)) rank[a[2]] = a[1]
        }
      }
      {
        r = ($2 in rank) ? rank[$2] : 9999
        printf "%04d\t%s\t%s\n", r, $1, $2
      }' "$CANDIDATE_FILE" | sort -t $'\t' -k1,1n -k3,3 > "$RANKED_FILE"; then
    awk -F $'\t' '{ printf "9999\t%s\t%s\n", $1, $2 }' "$CANDIDATE_FILE" > "$RANKED_FILE"
  fi
else
  awk -F $'\t' '{ printf "9999\t%s\t%s\n", $1, $2 }' "$CANDIDATE_FILE" > "$RANKED_FILE"
fi

CANDIDATE_COUNT=$(wc -l < "$RANKED_FILE" | tr -d ' ')

if [[ "$CANDIDATE_COUNT" == "0" ]]; then
  rm -f "$CANDIDATE_FILE"
  rm -f "$RANKED_FILE"
  [[ -n "$CONTEXT_RANK_FILE" ]] && rm -f "$CONTEXT_RANK_FILE"
  tmux display-message "No files found in ${TARGET_CWD/#$HOME/~}"
  exit 0
fi

SELECTED=$(
  cat "$RANKED_FILE" | fzf \
        --ansi \
        --multi \
        --delimiter $'\t' \
        --with-nth=2 \
        --reverse \
        --no-sort \
        --pointer '▶' \
        --no-info \
        --header 'Select files to insert as @path' \
        --prompt '@ > ' \
        --preview "$PREVIEW_CMD" \
        --preview-window 'up,40%,border-bottom' \
        --bind 'ctrl-/:toggle-preview'
) || exit 0
rm -f "$CANDIDATE_FILE"
rm -f "$RANKED_FILE"
[[ -n "$CONTEXT_RANK_FILE" ]] && rm -f "$CONTEXT_RANK_FILE"

[[ -z "$SELECTED" ]] && exit 0

# Build space-separated "@path" tokens, one per selected file.
TOKENS=()
while IFS= read -r line; do
  path=$(printf '%s\n' "$line" | "$AWK_BIN" -F$'\t' '{print $3}')
  [[ -n "$path" ]] && TOKENS+=("@$path ")
done <<< "$SELECTED"

# Paste into the target pane without submitting (-l = literal).
tmux send-keys -t "$SEND_PANE" -l "${TOKENS[*]}"
