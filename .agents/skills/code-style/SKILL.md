---
name: code-style
description: Enforce coding style, patterns, and anti-patterns. Use when writing, editing, or generating any code to ensure it matches the user's conventions and quality bar.
user_invocable: true
---

# Code Style

Enforce these rules when writing or modifying code. When in doubt, keep it simple.

## Core Principles

1. **No over-engineering.** Don't create abstractions, helpers, or utilities for one-off operations. Three similar lines > a premature abstraction. Only abstract when there's a proven, repeated need.
2. **Type safety is non-negotiable.** No `any`. No type assertions unless truly unavoidable (and flagged with a comment explaining why). Use `unknown` when a type isn't known. Use discriminated unions over optional fields for state modeling.
3. **Code speaks for itself.** Almost no comments. Only add them for genuinely tricky "why" explanations or TODO/FIXME markers. No JSDoc unless it's a public library API. No restating what the code does.
4. **Errors are values.** Prefer Result types (`neverthrow`, `@praha/byethrow` if available) for business logic. Throws are OK for truly exceptional/unrecoverable situations (network failures, etc.). Never silently swallow errors.
5. **Keep it flat.** Early returns and guard clauses over nested if/else. Never nest ternaries — single-condition ternaries are fine, otherwise use if/else.

## TypeScript Rules

Read `references/typescript.md` for detailed TypeScript conventions.

## Naming

- Descriptive, intention-revealing names. No abbreviations (`getUserPermissions` not `getUsrPerms`).
- Booleans read as questions: `isValid`, `hasAccess`, `canEdit`.
- File names: kebab-case unless the project already uses something else.

## Imports & Modules

- **No barrel exports** (index.ts re-exports). Always import directly from the source file.
- Use path aliases (`@/`) when imports would go more than 2 levels deep. Relative imports are fine for siblings and one level up.

## Structure

- Keep functions small and single-purpose.
- Colocate related code. Don't split across files unless there's a real reason.
- Prefer composition over inheritance.
- No magic numbers or strings — use named constants.

## Immutability

- Prefer immutable patterns (spread, `.map`, `.filter`) over mutation (`.push`, `.splice`).
- Use `readonly` for data that shouldn't be mutated.
- Exception: hot paths or complex backend logic where mutation is clearly better for performance. Use judgment.

## What NOT To Do

Read `references/anti-patterns.md` for a list of things to avoid.

## Gotchas

- Don't add error handling for scenarios that can't happen. Trust internal code and framework guarantees.
- Don't add feature flags or backwards-compatibility shims — just change the code.
- Don't rename unused variables to `_var` or add `// removed` comments. If it's unused, delete it.
- Don't wrap simple operations in try/catch "just in case". Only validate at system boundaries.
- Don't add docstrings, comments, or type annotations to code you didn't change.
- Don't add config/options/flags for hypothetical future requirements.

## Package Manager Preference

`bun` > `pnpm` > `npm`. Use whatever the project already has, but for new projects prefer bun.
