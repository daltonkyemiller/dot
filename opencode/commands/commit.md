
---
description: This skill should be used when the user asks to "commit", "commit changes", "create commits", "make a commit", "git commit", or discusses committing code changes. It creates well-structured commits following Conventional Commits standards, intelligently grouping related changes.
---

# Conventional Commits Skill

Create well-structured git commits following Conventional Commits standards, with intelligent grouping of related changes.

## Conventional Commits Format

All commits MUST follow this format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types (Required)

- **feat**: A new feature (correlates with MINOR in SemVer)
- **fix**: A bug fix (correlates with PATCH in SemVer)
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- **ci**: Changes to CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Scope (Optional)

A scope provides additional contextual information:
- Should be a noun describing a section of the codebase
- Surrounded by parentheses: `feat(parser): add ability to parse arrays`
- Examples: `api`, `ui`, `auth`, `database`, `cli`

### Breaking Changes

- Add an exclamation mark after type/scope: `feat(api)!: send an email to the customer when a product is shipped`
- Or include `BREAKING CHANGE:` in the footer

### Examples

```
feat: add email notifications for order confirmations
```

```
fix(auth): resolve session timeout issue on mobile devices

The session was expiring prematurely due to incorrect
timezone handling in the token validation logic.

Fixes #123
```

```
feat(api)!: change authentication from cookies to JWT

BREAKING CHANGE: API now requires Bearer token authentication.
Cookie-based auth is no longer supported.
```

## Workflow

### Step 1: Analyze Changes

Run these commands to understand the current state:
```bash
git status
git diff HEAD
git log --oneline -5
```

### Step 2: Determine Grouping Strategy

**Single Commit** - Use when:
- All changes are related to one logical unit of work
- Changes touch only a few files with a common purpose
- There's a single clear type (all fixes, all features, etc.)

**Multiple Commits** - Use when changes span:
- Different types (features AND fixes AND refactoring)
- Different scopes/areas (auth AND ui AND api)
- Independent logical units that could be reviewed/reverted separately
- Mixed concerns (new feature + unrelated test fixes)

### Step 3: Group Changes Logically

When splitting into multiple commits, group by:

1. **By Type First**: Separate fixes from features from refactors
2. **By Scope Second**: Within the same type, separate by area of codebase
3. **By Independence**: Changes that make sense together stay together

Example groupings:
- All bug fixes in one area -> single `fix(scope)` commit
- New feature files + feature tests -> single `feat` commit
- Unrelated formatting changes -> separate `style` commit
- Config updates -> separate `chore` or `build` commit

### Step 4: Create Commits

For each logical group:

1. Stage only the relevant files:
   ```bash
   git add <specific-files>
   ```

2. Create the commit with proper conventional commit message:
   ```bash
   git commit -m "$(cat <<'EOF'
   type(scope): concise description

   Optional body with more details.
   EOF
   )"
   ```

3. Repeat for remaining groups

## Important Guidelines

1. **Never stage everything blindly** - Review changes and stage intentionally
2. **Keep commits atomic** - Each commit should be a complete, working unit
3. **Description should be imperative mood** - "add feature" not "added feature"
4. **First line max 72 characters** - Keep it concise
5. **Body wraps at 72 characters** - For readability in terminals
6. **Reference issues when applicable** - Use `Fixes #123` or `Refs #456`

## Decision Framework

```
Are all changes related to one purpose?
├── Yes -> Single commit with appropriate type
└── No -> Split by type/scope
    ├── Group 1: feat(scope1): ...
    ├── Group 2: fix(scope2): ...
    └── Group 3: chore: ...
```

When in doubt, prefer fewer commits if changes are cohesive, but always split when:
- Changes have different types (don't mix feat and fix)
- Changes affect completely different parts of the codebase
- One change could be reverted independently of another
