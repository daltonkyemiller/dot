# TypeScript Conventions

## Variables & Constants

- `const` over `let`. Never `var`.
- Use `as const` for literal objects/arrays that shouldn't widen.
- Prefer `satisfies` over `as` for type checking without widening.

## Types

- `unknown` over `any` when a type isn't known.
- Discriminated unions over optional fields for state:
  ```ts
  // Good
  type State = { status: 'loading' } | { status: 'success'; data: T } | { status: 'error'; error: Error }

  // Bad
  type State = { loading?: boolean; data?: T; error?: Error }
  ```
- Use `readonly` for data that shouldn't mutate.
- Derive types from source of truth (`typeof`, `keyof`, `ReturnType`, `Awaited`, etc.) instead of duplicating.
- Use template literal types and mapped types where they reduce duplication.

## Error Handling

- Prefer Result types (`neverthrow` or `@praha/byethrow`) for business logic.
- Pattern:
  ```ts
  import { ok, err, Result } from 'neverthrow'

  function parseConfig(raw: string): Result<Config, ParseError> {
    // ...
    return ok(config)
    // or
    return err(new ParseError('missing field'))
  }
  ```
- Throws OK for truly exceptional situations (network down, file system errors).
- At system boundaries (API handlers, CLI entry points), catch and convert to appropriate responses.

## Functions

- Prefer arrow functions for callbacks and short expressions.
- Use named function declarations for top-level functions (hoisting + better stack traces).
- Keep parameter lists short. If >3 params, use an options object.
- Use generics when they reduce duplication, not for the sake of it.

## Assertions & Casting

- Avoid `!` (non-null assertion). If you truly need it, add a comment explaining why.
- Avoid `as` type assertions. Prefer type guards, `satisfies`, or narrowing.
- If a cast is truly necessary, flag it:
  ```ts
  // SAFETY: response is validated by zod schema above
  const data = response as ValidatedData
  ```
