# Shared Agent Instructions

These instructions apply across coding agents. Follow them when working in any local repo.

## Skill Use

Before writing or modifying code, use the `code-style` skill:

- If your agent has a native skill tool, load `code-style`.
- Otherwise, read `/home/dalton/.agents/skills/code-style/SKILL.md` and treat it as mandatory.

For frontend work, proactively use the relevant frontend skills before implementation:

- `impeccable` for new interfaces, pages, components, or substantial UI changes.
- `ui` for general UI exploration, build, and refinement.
- `layout` for spacing, alignment, hierarchy, and composition.
- `typeset` for typography, sizing, readability, and text hierarchy.
- `polish` before finishing UI work.
- `adapt` when responsive behavior, mobile, viewport changes, or touch targets matter.
- `animate` or `web-animation-design` when adding or reviewing motion.
- `testing-practices` when adding or changing tests.

Do not wait for an explicit reminder when the task clearly matches a skill description.

## Commit Guidelines

- Always use conventional commits, such as `feat:`, `fix:`, `chore:`, `docs:`, or `refactor:`.
- Never add co-author lines to commit messages.

## Coding Practices

These are a short always-on summary. The full source of truth is `code-style`.

- Prefer simple, focused changes over broad refactors.
- Avoid premature abstractions and unnecessary indirection.
- Do not over-abstract or under-abstract. Prefer composition over inheritance.
- Keep functions small and single-purpose.
- Prefer early returns and guard clauses over nested control flow.
- Never use nested ternaries. Single-condition ternaries are fine; otherwise use if/else statements.
- Use descriptive names. Avoid abbreviations.
- Boolean names should read as questions, such as `isValid`, `hasAccess`, or `canEdit`.
- Prefer kebab-case file names unless the project already uses another convention.
- Colocate related code unless there is a real reason to split it.
- Avoid magic numbers and strings. Use named constants.
- Code should be self-documenting and readable without comments. Only add comments for genuinely complex logic.

## TypeScript

- Prefer type safety. No `any`.
- Prefer `const` over `let`. Never use `var`.
- Prefer `unknown` when a type is not known.
- Avoid type assertions and non-null assertions unless truly unavoidable. If one is unavoidable, call it out.
- Prefer discriminated unions over optional-field state modeling.
- Use `readonly` for data that should not be mutated.
- Prefer immutable patterns unless mutation is clearer for a hot path or complex backend logic.

## Error Handling

- Handle errors explicitly at system boundaries.
- Do not silently swallow errors.
- Prefer typed error handling over generic catch-all patterns.
