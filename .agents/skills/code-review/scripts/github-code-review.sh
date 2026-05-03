#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${CODE_REVIEW_DIR:-$HOME/Documents/code-reviews}"
LIMIT="${CODE_REVIEW_LIMIT:-200}"

usage() {
  cat >&2 <<'EOF'
Usage:
  github-code-review.sh [owner] [period...]

Examples:
  github-code-review.sh better-bookkeeping past week
  github-code-review.sh last week
  github-code-review.sh past 14 days
  github-code-review.sh since 2026-04-01
EOF
}

is_period_start() {
  case "${1:-}" in
    ""|today|yesterday|last|past|since|this) return 0 ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_period() {
  local phrase="$*"
  [[ -n "$phrase" ]] || phrase="past week"

  local since until
  until=$(date +%F)

  case "$phrase" in
    "today")
      since="$until"
      ;;
    "yesterday")
      since=$(date -d "yesterday" +%F)
      until="$since"
      ;;
    "past week")
      since=$(date -d "7 days ago" +%F)
      ;;
    "last week")
      since=$(date -d "last monday -7 days" +%F)
      until=$(date -d "last monday -1 day" +%F)
      ;;
    "past "*)
      local days
      days=${phrase#past }
      days=${days% days}
      [[ "$phrase" == "past "*days ]] || { echo "Invalid period: $phrase" >&2; exit 1; }
      [[ "$days" =~ ^[0-9]+$ ]] || { echo "Invalid period: $phrase" >&2; exit 1; }
      since=$(date -d "$days days ago" +%F)
      ;;
    "since "*)
      since=${phrase#since }
      [[ "$since" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "Invalid since date: $since" >&2; exit 1; }
      ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      since="$phrase"
      ;;
    *)
      echo "Unsupported period: $phrase" >&2
      echo "Supported: today, yesterday, past week, last week, past N days, since YYYY-MM-DD" >&2
      exit 1
      ;;
  esac

  printf '%s\t%s\t%s\n' "$since" "$until" "$phrase"
}

require_tools() {
  command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
  command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }
  gh auth status >/dev/null 2>&1 || { echo "gh is not authenticated. Run: gh auth login" >&2; exit 1; }
}

json_count() {
  jq 'length' "$1"
}

write_pr_rows() {
  jq -r '
    if length == 0 then
      "_No pull requests found for this range._"
    else
      "| Repo | PR | State | Author | Updated | Links |",
      "| --- | --- | --- | --- | --- | --- |",
      (.[] | [
        (.repository.nameWithOwner // ""),
        ("[#" + (.number | tostring) + " " + (.title // "" | gsub("\\|"; "\\|")) + "](" + (.url // "") + ")"),
        (.state // ""),
        (.author.login // ""),
        ((.updatedAt // .createdAt // "")[0:10]),
        ("[diff](" + (.url // "") + ".diff) · [files](" + (.url // "") + "/files)")
      ] | "| " + join(" | ") + " |")
    end
  ' "$1"
}

write_commit_rows() {
  jq -r '
    if length == 0 then
      "_No commits found for this range._"
    else
      "| Repo | Commit | Author Date | Author | Message | Links |",
      "| --- | --- | --- | --- | --- | --- |",
      (.[] | [
        (.repository.nameWithOwner // .repository.fullName // .repository.name // ""),
        ("[`" + ((.sha // "")[0:7]) + "`](" + (.url // "") + ")"),
        ((.commit.author.date // .commit.committer.date // "")[0:10]),
        (.author.login // .commit.author.name // ""),
        ((.commit.messageHeadline // .commit.message // "" | split("\n")[0]) | gsub("\\|"; "\\|")),
        ("[diff](" + (.url // "") + ".diff)")
      ] | "| " + join(" | ") + " |")
    end
  ' "$1"
}

write_my_pr_rows() {
  jq -r '
    if length == 0 then
      "_No pull requests authored by the authenticated user found for this range._"
    else
      "| Repo | PR | State | Updated | Links |",
      "| --- | --- | --- | --- | --- |",
      (.[] | [
        (.repository.nameWithOwner // ""),
        ("[#" + (.number | tostring) + " " + (.title // "" | gsub("\\|"; "\\|")) + "](" + (.url // "") + ")"),
        (.state // ""),
        ((.updatedAt // .createdAt // "")[0:10]),
        ("[diff](" + (.url // "") + ".diff) · [files](" + (.url // "") + "/files)")
      ] | "| " + join(" | ") + " |")
    end
  ' "$1"
}

write_my_commit_rows() {
  jq -r '
    if length == 0 then
      "_No commits authored by the authenticated user found for this range._"
    else
      "| Repo | Commit | Author Date | Message | Links |",
      "| --- | --- | --- | --- | --- |",
      (.[] | [
        (.repository.nameWithOwner // .repository.fullName // .repository.name // ""),
        ("[`" + ((.sha // "")[0:7]) + "`](" + (.url // "") + ")"),
        ((.commit.author.date // .commit.committer.date // "")[0:10]),
        ((.commit.messageHeadline // .commit.message // "" | split("\n")[0]) | gsub("\\|"; "\\|")),
        ("[diff](" + (.url // "") + ".diff)")
      ] | "| " + join(" | ") + " |")
    end
  ' "$1"
}

write_my_commit_theme_rows() {
  jq -r '
    if length == 0 then
      "_No authored commit themes available._"
    else
      "| Repo | Authored commits | Main themes |",
      "| --- | ---: | --- |",
      (group_by(.repository.nameWithOwner // .repository.fullName // .repository.name // "")[] |
        . as $items |
        [
          ($items[0].repository.nameWithOwner // $items[0].repository.fullName // $items[0].repository.name // ""),
          ($items | length | tostring),
          "_Agent: summarize these commits by theme._"
        ] | "| " + join(" | ") + " |")
    end
  ' "$1"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_tools

  local owner="" period_parts=()
  if [[ $# -gt 0 ]] && ! is_period_start "$1"; then
    owner="$1"
    shift
  fi
  period_parts=("$@")

  local login
  login=$(gh api user --jq '.login')

  local period since until period_label
  period=$(resolve_period "${period_parts[@]}")
  since=$(printf '%s' "$period" | cut -f1)
  until=$(printf '%s' "$period" | cut -f2)
  period_label=$(printf '%s' "$period" | cut -f3)

  local scope_label slug
  if [[ -n "$owner" ]]; then
    scope_label="$owner"
    slug="$owner"
  else
    scope_label="$login"
    slug="$login"
  fi

  mkdir -p "$OUTPUT_DIR"

  local stamp report pr_json commit_json my_pr_json my_commit_json
  stamp=$(date +%Y%m%d-%H%M%S)
  report="$OUTPUT_DIR/code-review-${slug}-${since}-to-${until}-${stamp}.md"
  pr_json=$(mktemp)
  commit_json=$(mktemp)
  my_pr_json=$(mktemp)
  my_commit_json=$(mktemp)
  trap 'rm -f "${pr_json:-}" "${commit_json:-}" "${my_pr_json:-}" "${my_commit_json:-}"' EXIT

  if [[ -n "$owner" ]]; then
    gh search prs --owner "$owner" --updated "$since..$until" --sort updated --order desc --limit "$LIMIT" \
      --json repository,number,title,state,author,createdAt,updatedAt,closedAt,url,labels,commentsCount > "$pr_json"
    gh search commits --owner "$owner" --author-date "$since..$until" --sort author-date --order desc --limit "$LIMIT" \
      --json repository,sha,url,author,commit > "$commit_json"
    gh search prs --owner "$owner" --author "$login" --updated "$since..$until" --sort updated --order desc --limit "$LIMIT" \
      --json repository,number,title,state,author,createdAt,updatedAt,closedAt,url,labels,commentsCount > "$my_pr_json"
    gh search commits --owner "$owner" --author "$login" --author-date "$since..$until" --sort author-date --order desc --limit "$LIMIT" \
      --json repository,sha,url,author,commit > "$my_commit_json"
  else
    gh search prs --involves "$login" --updated "$since..$until" --sort updated --order desc --limit "$LIMIT" \
      --json repository,number,title,state,author,createdAt,updatedAt,closedAt,url,labels,commentsCount > "$pr_json"
    gh search commits --author "$login" --author-date "$since..$until" --sort author-date --order desc --limit "$LIMIT" \
      --json repository,sha,url,author,commit > "$commit_json"
    gh search prs --author "$login" --updated "$since..$until" --sort updated --order desc --limit "$LIMIT" \
      --json repository,number,title,state,author,createdAt,updatedAt,closedAt,url,labels,commentsCount > "$my_pr_json"
    cp "$commit_json" "$my_commit_json"
  fi

  local pr_count commit_count my_pr_count my_commit_count
  pr_count=$(json_count "$pr_json")
  commit_count=$(json_count "$commit_json")
  my_pr_count=$(json_count "$my_pr_json")
  my_commit_count=$(json_count "$my_commit_json")

  {
    printf '# Code Review: %s\n\n' "$scope_label"
    printf -- '- Period: `%s` (`%s` to `%s`)\n' "$period_label" "$since" "$until"
    printf -- '- Scope: `%s`\n' "$scope_label"
    printf -- '- Generated: `%s`\n' "$(date -Is)"
    printf -- '- Pull requests found: `%s`\n' "$pr_count"
    printf -- '- Commits found: `%s`\n' "$commit_count"
    printf -- '- My pull requests found: `%s`\n' "$my_pr_count"
    printf -- '- My commits found: `%s`\n' "$my_commit_count"
    printf -- '- Search limit per section: `%s`\n\n' "$LIMIT"

    printf '## Executive Summary\n\n'
    printf '_Agent: replace this section with a concise summary of the most important themes, risk areas, and review priorities._\n\n'

    printf '## My Changes\n\n'
    printf '_Agent: summarize the authenticated user'\''s work here. Include authored PRs, authored commits, direct commits, and branch-only work that may not appear in PR search._\n\n'

    printf '### My PRs\n\n'
    write_my_pr_rows "$my_pr_json"
    printf '\n\n'

    printf '### My Commit Themes\n\n'
    write_my_commit_theme_rows "$my_commit_json"
    printf '\n\n'

    printf '### My Authored Commits\n\n'
    write_my_commit_rows "$my_commit_json"
    printf '\n\n'

    printf '### Direct / Branch Commits\n\n'
    printf '_Agent: add commits from non-default branches or direct branch work that GitHub Search did not surface. Use `gh api repos/<owner>/<repo>/commits?sha=<branch>&since=<since>T00:00:00Z&until=<until>T23:59:59Z&per_page=100` when a branch is known or suspected._\n\n'

    printf '## Review Priorities\n\n'
    printf -- '- _Agent: list PRs or commits that deserve closer human review._\n'
    printf -- '- _Agent: call out large changes, risky migrations, auth/payment/data changes, or unclear test coverage._\n\n'

    printf '## Pull Requests\n\n'
    write_pr_rows "$pr_json"
    printf '\n\n'

    printf '## Commits\n\n'
    write_commit_rows "$commit_json"
    printf '\n\n'

    printf '## Suggested Deep Dives\n\n'
    printf '_Agent: add repo-specific notes and direct `gh pr view` / diff links for important changes._\n\n'

    printf '## Caveats\n\n'
    printf -- '- GitHub search results are capped by `CODE_REVIEW_LIMIT` or the script default.\n'
    printf -- '- Private repository coverage depends on the authenticated `gh` account permissions.\n'
    printf -- '- PRs are selected by updated date; commits are selected by author date.\n'
  } > "$report"

  printf '%s\n' "$report"
}

main "$@"
