---
name: code-review
description: Generate a component-backed MDX code review site for recent GitHub work using gh and mdx-preview. Use when the user invokes /code-review, asks to review an organization or account over a time range, or wants a visual review artifact with links to PRs, commits, diffs, and notable changes.
user_invocable: true
args:
  - name: scope
    description: "Optional GitHub organization or owner, such as acme. Omit to review work tied to the authenticated GitHub account."
  - name: period
    description: "Optional time range, such as past week, last week, past 14 days, today, yesterday, or since YYYY-MM-DD."
---

# GitHub Code Review Report

Generate a durable MDX review artifact of recent GitHub code changes with Codiff links for PRs and commits, plus links to diffs and review targets. Use `mdx-sites` and the `mdx-preview` component registry for the artifact. Prefer Codiff commands for local review targets when the `codiff` binary is installed.

## Workflow

1. Parse the request:
   - `/code-review acme past week` means owner/org `acme`, period `past week`.
   - `/code-review last week` means the authenticated GitHub account, period `last week`.
   - If no period is provided, use `past week`.

2. Run the bundled MDX report generator:
   ```bash
   .agents/skills/code-review/scripts/github-code-review.sh [scope] [period...]
   ```

   It prints an `index.mdx` path inside a timestamped report directory.

3. Inspect the generated MDX source and load the components available to that artifact:
   ```bash
   mdx-preview components list <report-directory>
   ```

   The generated source already imports `Callout`, `Metric`, and `TableOfContents`. Use only components reported by this command; do not assume a component exists or invent custom layout markup.

4. Check whether Codiff is available:
   ```bash
   command -v codiff
   ```

   If available, use Codiff for review links instead of GitHub's PR/commit UI. For GitHub PRs and commits, use remote protocol links as the primary Markdown link:
   - Remote GitHub PR URL format: `codiff://github/<owner>/<repo>/pull/<number>`
   - Remote GitHub commit URL format: `codiff://github/<owner>/<repo>/commit/<sha>`
   - Example: `codiff://github/better-bookkeeping/abacus/pull/1875`
   - Example: `codiff://github/better-bookkeeping/abacus/commit/9672c6de226ab14defad22260c4d93cfca220328`

   Keep normal GitHub links only when Codiff cannot open that target directly.

5. Enrich the MDX report where useful:
   - Group changes by repo and theme.
   - Highlight risky or review-worthy changes.
   - Add direct Codiff links to important PRs and commits.
   - Replace every `_Agent:` placeholder; do not leave scaffold text in the finished artifact.
   - Keep standard Markdown for prose and the PR/commit tables. Use components only where they make the review easier to understand:
     - `Callout` for high-severity review risks or important caveats.
     - `Flow` for a three-or-more-step user or deployment sequence.
     - `Diagram` for a cross-repository handoff or trust boundary with three to eight nodes and no more than twelve directed edges.
     - `FileMap` when a deep dive spans at least three consequential files.
     - `Checklist` for a focused reviewer test matrix.
     - `Comparison` only when contrasting two viable implementations or behaviors.
   - Do not add decorative dashboards, duplicate the generator's metrics, or force a visualization into a single-repository/simple change. Prefer one focused relationship visualization per substantial review, not a component at every heading.
   - For five or more main sections, retain the generated `TableOfContents` and keep every heading's stable `id` aligned with it.
   - For important PRs and commits, add a `Codiff` column or note with the best local link and command:
     - Remote GitHub PR URL format: `codiff://github/<owner>/<repo>/pull/<number>`
     - Remote GitHub commit URL format: `codiff://github/<owner>/<repo>/commit/<sha>`
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

6. Validate and build the shareable static artifact:
   ```bash
   mdx-preview build <report-directory> --out <output-directory>/dist/<report-slug>
   ```

   Do not publish private review material unless the user explicitly asks. If they do, use `mdx-preview publish <report-directory> --out <output-directory>/dist/<report-slug>`.

7. When done, print the final `index.mdx` file location exactly, followed by the static build directory.

## Report Quality Bar

The report should include:

- Scope, date range, and generated metrics.
- Executive summary with the most important review conclusion first.
- A `My Changes` section for the authenticated user, including authored PRs, authored commits, direct commits, and branch-only commits where applicable.
- Repository-by-repository summary.
- PR table with title, repo, state, author, updated/merged date, and links.
- Commit table with repo, SHA, author date, message, diff links, and Codiff commands when `codiff` is installed.
- Review checklist or notes for changes that deserve a closer look.
- At least one component-backed visualization when multiple repositories or trust boundaries form a review-relevant flow; otherwise, a concise `Callout` or plain Markdown is sufficient.
- Gaps or caveats, such as GitHub search limits, inaccessible private repos, or omitted huge diffs.

## Rules

- Use `gh` as the source of truth.
- If `gh auth status` fails, stop and tell the user to authenticate.
- Prefer links and Codiff commands over copied patches.
- Keep the generated report as MDX and the static build directory as the canonical export.
- Always finish by printing the MDX file path and static build directory.
