import { test, expect } from '@playwright/test'

const hasTestUser = !!process.env.TEST_USER_EMAIL && !!process.env.TEST_USER_PASSWORD

test.describe('guest browse → activity → build (no auth required)', () => {
  test('home page loads', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveTitle(/ScrapLab/i)
  })

  test('explore listing renders activities or an honest empty state', async ({ page }) => {
    await page.goto('/explore')
    await expect(page.getByPlaceholder('Search activities…')).toBeVisible()
    // Either real cards render, or the explicit "no activities" copy does —
    // never an indefinite loading skeleton.
    await expect(
      page.locator('a[href^="/explore/"]').first().or(page.getByText(/no activities match/i))
    ).toBeVisible({ timeout: 15_000 })
  })

  test('activity detail page shows a working build link or an honest non-guided message', async ({ page }) => {
    await page.goto('/explore')
    const firstCard = page.locator('a[href^="/explore/"]').first()
    await firstCard.waitFor({ timeout: 15_000 })
    await firstCard.click()

    const buildLink = page.getByRole('link', { name: /let's build it!/i })
    const openEndedNotice = page.getByText(/open-ended activity/i)
    await expect(buildLink.or(openEndedNotice)).toBeVisible()
  })

  test('manual material picker is reachable without signing in', async ({ page }) => {
    await page.goto('/create/manual')
    await expect(page).not.toHaveURL(/\/auth/)
  })
})

test.describe('authenticated build persistence', () => {
  test.skip(!hasTestUser, 'set TEST_USER_EMAIL/TEST_USER_PASSWORD to run against a disposable staging account')

  test('start → advance a step → reload resumes at the same step', async ({ page }) => {
    await page.goto('/auth')
    await page.getByPlaceholder('you@example.com').fill(process.env.TEST_USER_EMAIL!)
    await page.getByPlaceholder('••••••••').fill(process.env.TEST_USER_PASSWORD!)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL('/')

    // Requires a known guided project slug/id in the target environment.
    const projectId = process.env.TEST_PROJECT_ID
    test.skip(!projectId, 'set TEST_PROJECT_ID to a real guided project id/slug in the target environment')

    await page.goto(`/build/${projectId}`)
    await page.getByRole('button', { name: /next step/i }).click()
    await page.reload()
    // Resumed at step 2, not reset to step 1.
    await expect(page.getByText(/^step 2\//i)).toBeVisible()
  })
})
