# Vitest Conventions

## File Structure

- Test files live next to the code they test: `foo.ts` + `foo.test.ts`.
- Name test files `*.test.ts`, not `*.spec.ts` (unless the project already uses spec).

## Test Structure

```ts
import { describe, it, expect } from 'vitest'

describe('parseConfig', () => {
  it('parses valid JSON config', () => {
    const result = parseConfig('{"port": 3000}')
    expect(result).toEqual(ok({ port: 3000 }))
  })

  it('returns error for invalid JSON', () => {
    const result = parseConfig('not json')
    expect(result.isErr()).toBe(true)
  })
})
```

### Naming

- `describe` blocks: name of the unit (function, class, module)
- `it` blocks: describe the behavior, not the implementation. Read as "it [does something]"
- Bad: `it('calls fetch with correct params')`
- Good: `it('returns user profile for valid ID')`

## Assertions

- `toEqual` for deep equality (value comparison)
- `toBe` for reference equality or primitives
- `toMatchObject` only when you intentionally want partial matching
- Use `expect.assertions(n)` in async tests with catch blocks to ensure assertions run

## Mocking

- Prefer dependency injection over `vi.mock` when possible
- If you must mock:
  ```ts
  import { vi } from 'vitest'

  const mockFetch = vi.fn()
  ```
- Reset mocks in `beforeEach`, not `afterEach` — guarantees clean state before each test
- Never mock the module under test

## Async Tests

```ts
it('fetches data', async () => {
  const result = await fetchData('test-id')
  expect(result).toEqual(expected)
})
```

- Always `await` — don't return promises
- Use `vi.useFakeTimers()` for time-dependent tests, but call `vi.useRealTimers()` in cleanup

## Test Isolation

- Each test should be independent. No shared mutable state between tests.
- Use `beforeEach` for setup, not `beforeAll` (unless expensive and truly readonly)
- If tests need a database, use transactions that roll back
