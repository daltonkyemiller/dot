# Playwright Conventions

## File Structure

- E2E tests in `e2e/` or `tests/` at the project root (follow project convention)
- Name files by feature or flow: `auth.test.ts`, `checkout.test.ts`

## Test Structure

```ts
import { test, expect } from '@playwright/test'

test.describe('login flow', () => {
  test('logs in with valid credentials', async ({ page }) => {
    await page.goto('/login')
    await page.getByLabel('Email').fill('user@example.com')
    await page.getByLabel('Password').fill('password')
    await page.getByRole('button', { name: 'Sign in' }).click()
    await expect(page.getByText('Dashboard')).toBeVisible()
  })
})
```

## Locators

Prefer in this order:
1. `getByRole` — most resilient, matches accessibility tree
2. `getByLabel` — for form fields
3. `getByText` — for visible text content
4. `getByTestId` — when semantic locators don't work

Avoid:
- CSS selectors (`.class`, `#id`) — brittle
- XPath — unreadable
- `nth` selectors — order-dependent

## Assertions

- Use `expect(locator)` web-first assertions — they auto-retry:
  ```ts
  await expect(page.getByText('Success')).toBeVisible()
  await expect(page.getByRole('button')).toBeDisabled()
  ```
- Don't use `page.waitForSelector` + manual checks — that's the old pattern

## Page Objects

Use page objects for repeated flows (login, navigation), but don't over-abstract:

```ts
class LoginPage {
  constructor(private page: Page) {}

  async login(email: string, password: string) {
    await this.page.goto('/login')
    await this.page.getByLabel('Email').fill(email)
    await this.page.getByLabel('Password').fill(password)
    await this.page.getByRole('button', { name: 'Sign in' }).click()
  }
}
```

## Common Patterns

- **Auth state reuse**: Use `storageState` to save/restore auth instead of logging in every test
- **API seeding**: Use `request` fixture to seed test data via API before UI tests
- **Network interception**: Use `page.route()` sparingly — prefer real backends when possible
- **Visual regression**: Use `expect(page).toHaveScreenshot()` for layout-critical flows

## Gotchas

- Don't use `page.waitForTimeout()` — it's a flake magnet. Wait for a specific condition.
- Don't assert on DOM structure — assert on visible behavior.
- Parallel tests must not share state (database rows, files, etc.).
