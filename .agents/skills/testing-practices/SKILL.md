---
name: testing-practices
description: Guide for writing tests — what to test, how to structure them, and common patterns with vitest and playwright. Use when writing tests, asked to add test coverage, or verifying code works.
user_invocable: true
---

# Testing Practices

## Philosophy

- Tests prove behavior, not implementation. Test what the code does, not how it does it.
- Don't mock what you don't own — prefer integration tests that hit real boundaries.
- A test that never fails is a test that doesn't test anything.

## What to Test

### Always test:
- Business logic and domain rules
- Edge cases and boundary conditions
- Error paths and failure modes
- Data transformations

### Don't bother testing:
- Simple pass-through functions
- Framework behavior (React rendering a div, Express calling middleware)
- Type-level guarantees (if the type system catches it, you don't need a runtime test)
- Implementation details (internal state, private methods, call counts)

## Vitest Patterns

Read `references/vitest.md` for patterns and conventions.

## Playwright Patterns

Read `references/playwright.md` for E2E testing patterns.

## Gotchas

- Don't mock the database in integration tests unless there's a specific reason. Real DB > mocks for catching migration and query issues.
- Don't use `test.each` for fundamentally different test cases — it hurts readability. Use it for parameterized variations of the same logic.
- Don't assert on snapshot unless the output is small and stable. Snapshots of large objects or UI are brittle.
- Prefer `toEqual` over `toMatchObject` when you want to assert the full shape — `toMatchObject` silently ignores extra fields.
