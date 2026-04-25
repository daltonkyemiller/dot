# Anti-Patterns to Avoid

These are patterns Claude commonly produces that do not match the desired code style.

## Over-Engineering

- **Unnecessary abstractions**: Don't create a `createHandler` factory when you have one handler. Don't create a `withRetry` wrapper for one call site.
- **Premature generics**: Don't parameterize a function that's only ever called with one type.
- **Config objects for fixed behavior**: Don't pass `{ retries: 3, timeout: 5000 }` as options when those values never change. Use named constants.
- **Wrapper functions that just forward**: If `getData()` just calls `fetch()` with no added logic, delete the wrapper.

## Error Handling

- **Catch-all try/catch**: Don't wrap entire function bodies in try/catch. Handle specific failure points.
- **Silent swallowing**: `catch (e) { /* ignore */ }` is almost never correct.
- **Redundant validation**: Don't validate internal function parameters that are already typed. Only validate at boundaries (user input, API responses, file reads).
- **Defensive coding against impossible states**: If the type system guarantees a value exists, don't null-check it.

## Verbosity

- **Restating the obvious in comments**: `// increment counter` above `counter++`.
- **JSDoc on everything**: Only on public library APIs, if at all.
- **Explicit return types on simple functions**: Let TypeScript infer when the return is obvious.
- **Verbose destructuring**: Don't destructure just to rename — only if it improves clarity.

## Structure

- **Barrel exports**: No `index.ts` files that just re-export. Import from the source.
- **Splitting tiny files**: Don't create `utils/formatDate.ts` for a one-liner. Colocate with its usage.
- **Deep nesting**: Refactor with early returns, not by extracting to a helper.
- **God components/functions**: If a function does 5 things, split it. But don't split a function that does one thing into 3 pieces.

## React-Specific

- **Unnecessary `useMemo`/`useCallback`**: Only memoize when there's a measured or obvious perf issue.
- **Prop drilling avoidance theater**: Don't create a context for 2 levels of props. Just pass them.
- **Effect chains**: Don't use `useEffect` to sync state that could be derived. Compute it inline or use `useMemo`.
- **Abstraction layers over simple hooks**: Don't create `useToggle` when `useState(false)` is perfectly clear.
