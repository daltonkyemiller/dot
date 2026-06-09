---
name: code-review
description: Generate a comprehensive GitHub code review report for recent work using the gh CLI. Use when the user invokes /code-review, asks to review an organization or account over a time range, or wants a Markdown summary with links to PRs, commits, diffs, and notable changes.
user_invocable: true
args:
  - name: scope
    description: "Optional GitHub organization or owner, such as acme. Omit to review work tied to the authenticated GitHub account."
  - name: period
    description: "Optional time range, such as past week, last week, past 14 days, today, yesterday, or since YYYY-MM-DD."
---

# GitHub Code Review Report

Generate a Markdown report of recent GitHub code changes with links to PRs, commits, diffs, and review targets. Prefer Codiff commands for local review targets when the `codiff` binary is installed.

## Workflow

1. Parse the request:
   - `/code-review acme past week` means owner/org `acme`, period `past week`.
   - `/code-review last week` means the authenticated GitHub account, period `last week`.
   - If no period is provided, use `past week`.

2. Run the bundled report generator:
   ```bash
   .agents/skills/code-review/scripts/github-code-review.sh [scope] [period...]
   ```

3. Open the generated Markdown report path printed by the script.

4. Check whether Codiff is available:
   ```bash
   command -v codiff
   ```

   If available, use Codiff for local diff review instead of GitHub's diff UI. When the `codiff://` URL handler is registered, add Markdown links that open Codiff directly. Keep normal GitHub links too, because not every Markdown viewer allows custom URL schemes.

5. Enrich the report where useful:
   - Group changes by repo and theme.
   - Highlight risky or review-worthy changes.
   - Add direct links to important PR diffs and commits.
   - For important PRs and commits, add a `Codiff` column or note with the best local link and command:
     - URL format: `codiff://open?repo=<url-encoded-absolute-repo-path>&pr=<number>`
     - GitHub PR URL format: `codiff://open?repo=<url-encoded-absolute-repo-path>&url=<url-encoded-github-pr-url>`
     - Commit URL format: `codiff://open?repo=<url-encoded-absolute-repo-path>&commit=<url-encoded-ref>`
     - Branch URL format: `codiff://open?repo=<url-encoded-absolute-repo-path>&branch=<url-encoded-ref>`
     - Walkthrough links add `&walkthrough=1`.
     - Current repository changes: `codiff`
     - Specific checkout: `codiff /path/to/repo`
     - Branch comparison: `codiff main` or `codiff --branch main`
     - Commit review: `codiff <sha>` or `codiff --commit <sha>`
     - Pull request review from inside the repo: `codiff '#<number>'` or `codiff pr <number>`
     - Pull request review from outside the repo: `codiff '#<number>' /path/to/repo`
     - Narrative walkthrough: `codiff -w <sha>`, `codiff -w '#<number>'`, or `codiff -w /path/to/repo`
   - When the report spans multiple repositories, include the repo path in Codiff commands whenever the likely working directory is ambiguous.
   - Always fill out the `My Changes` section for the authenticated `gh` user:
     - Summarize authored PRs together.
     - Summarize authored commits together by repo and theme.
     - Include direct commits and non-PR work, not just PRs.
     - Add a `Direct / Branch Commits` table for branch-only work that GitHub Search does not surface.
   - When expected personal work is missing from search results, check non-default branches directly with the GitHub commits API:
     ```bash
     gh api 'repos/<owner>/<repo>/commits?sha=<branch>&since=<YYYY-MM-DD>T00:00:00Z&until=<YYYY-MM-DD>T23:59:59Z&per_page=100'
     ```
     Use this for known active branches, branches mentioned by the user, or branches whose names clearly match the reviewed work.
   - For large or important PRs, inspect details with:
     ```bash
     gh pr view <number> --repo <owner/repo> --json title,url,author,mergedAt,changedFiles,additions,deletions,files,reviews
     gh pr diff <number> --repo <owner/repo>
     ```
   - Do not paste huge diffs into the report. Link to them and summarize the important parts.

6. When done, print the final Markdown file location exactly.

## Report Quality Bar

The report should include:

- Scope and date range.
- Executive summary.
- A `My Changes` section for the authenticated user, including authored PRs, authored commits, direct commits, and branch-only commits where applicable.
- Repository-by-repository summary.
- PR table with title, repo, state, author, updated/merged date, and links.
- Commit table with repo, SHA, author date, message, diff links, and Codiff commands when `codiff` is installed.
- Review checklist or notes for changes that deserve a closer look.
- Gaps or caveats, such as GitHub search limits, inaccessible private repos, or omitted huge diffs.

## Rules

- Use `gh` as the source of truth.
- If `gh auth status` fails, stop and tell the user to authenticate.
- Prefer links and Codiff commands over copied patches.
- Keep the generated report as Markdown.
- Always finish by printing the Markdown file path.
