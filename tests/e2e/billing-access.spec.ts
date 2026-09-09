import { test, expect } from '@playwright/test'

const hasTestUser = !!process.env.TEST_USER_EMAIL && !!process.env.TEST_USER_PASSWORD

test.describe('unauthenticated access boundaries (no auth required)', () => {
  test('private routes reject an unauthenticated request with 401, not a silent empty result', async ({ request }) => {
    const buildHistory = await request.get('/api/build-history')
    expect(buildHistory.status()).toBe(401)

    const savedProjects = await request.post('/api/saved-projects', {
      data: { projectId: '10000000-0000-0000-0000-000000000001' },
    })
    expect(savedProjects.status()).toBe(401)

    const deleteAccount = await request.delete('/api/me/delete-account')
    expect(deleteAccount.status()).toBe(401)
  })

  test('subscription page redirects an unauthenticated visitor to /auth', async ({ page }) => {
    await page.goto('/subscription')
    await expect(page).toHaveURL(/\/auth/)
  })

  test('guest recommendation usage is capped, not unlimited', async ({ request }) => {
    const body = { materialIds: ['00000000-0000-0000-0000-000000000001'], childAge: 6 }
    const results: number[] = []
    for (let i = 0; i < 4; i++) {
      const res = await request.post('/api/activity-recommendations', { data: body })
      results.push(res.status())
    }
    // First 3 succeed (200), the 4th is rate-limited (429) — same identity
    // (same test client / IP) reserving from the same guest daily quota.
    expect(results.filter((s) => s === 200).length).toBeLessThanOrEqual(3)
    expect(results.at(-1)).toBe(429)
  })

  test('scan-materials requires auth before it will even look at the upload', async ({ request }) => {
    const res = await request.post('/api/scan-materials')
    expect(res.status()).toBe(401)
  })
})

test.describe('authenticated billing UI (never performs a live purchase)', () => {
  test.skip(!hasTestUser, 'set TEST_USER_EMAIL/TEST_USER_PASSWORD to run against a disposable staging account')

  test('subscription page loads plan state and renders an upgrade or manage action', async ({ page }) => {
    await page.goto('/auth')
    await page.getByPlaceholder('you@example.com').fill(process.env.TEST_USER_EMAIL!)
    await page.getByPlaceholder('••••••••').fill(process.env.TEST_USER_PASSWORD!)
    await page.locator('button[type="submit"]').click()
    await expect(page).toHaveURL('/')

    await page.goto('/subscription')
    await expect(page).not.toHaveURL(/\/auth/)
    // Either an upgrade CTA (free) or a manage-billing action (Plus) —
    // never both, never neither.
    const upgrade = page.getByRole('button', { name: /upgrade to plus/i })
    const manage = page.getByRole('button', { name: /manage (subscription|billing)/i })
    await expect(upgrade.or(manage)).toBeVisible()
  })
})
