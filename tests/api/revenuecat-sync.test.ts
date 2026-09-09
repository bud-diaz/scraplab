import { beforeEach, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'
const mocks = vi.hoisted(() => ({ rpc: vi.fn(), from: vi.fn(), auth: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: mocks.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => mocks }))
import { POST } from '@/app/api/me/sync-revenuecat/route'
beforeEach(() => {
  vi.resetAllMocks()
  vi.stubEnv('REVENUECAT_SECRET_API_KEY', 'fake-test-key')
  mocks.auth.mockResolvedValue({ user: { id: 'user-1' } })
  mocks.rpc.mockImplementation((name: string) => Promise.resolve({ data: name === 'begin_billing_reconciliation' ? { status: 'ready', revision: 1, user_id: 'user-1' } : { status: 'applied', plan: 'plus' }, error: null }))
  mocks.from.mockReturnValue({ update: () => ({ eq: () => Promise.resolve({ error: null }) }) })
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue(Response.json({ subscriber: { entitlements: {} } })))
})
it('preserves Stripe Plus by reconciling only the Apple entitlement and returning aggregate plan', async () => {
  const response = await POST(new NextRequest('http://localhost/api/me/sync-revenuecat', { method: 'POST' }))
  expect(await response.json()).toEqual({ plan: 'plus' })
  expect(mocks.rpc).toHaveBeenCalledWith('apply_billing_reconciliation', expect.objectContaining({ p_provider: 'revenuecat', p_active: false }))
})

it('reconciles an active non-expired entitlement as active', async () => {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue(
      Response.json({
        subscriber: { entitlements: { plus: { expires_date: new Date(Date.now() + 86_400_000).toISOString() } } },
      }),
    ),
  )
  await POST(new NextRequest('http://localhost/api/me/sync-revenuecat', { method: 'POST' }))
  expect(mocks.rpc).toHaveBeenCalledWith(
    'apply_billing_reconciliation',
    expect.objectContaining({ p_provider: 'revenuecat', p_active: true }),
  )
})

it('reconciles an expired entitlement as inactive', async () => {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue(
      Response.json({
        subscriber: { entitlements: { plus: { expires_date: new Date(Date.now() - 86_400_000).toISOString() } } },
      }),
    ),
  )
  await POST(new NextRequest('http://localhost/api/me/sync-revenuecat', { method: 'POST' }))
  expect(mocks.rpc).toHaveBeenCalledWith(
    'apply_billing_reconciliation',
    expect.objectContaining({ p_provider: 'revenuecat', p_active: false }),
  )
})

it('reconciles a lifetime entitlement (null expires_date) as active', async () => {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue(Response.json({ subscriber: { entitlements: { plus: { expires_date: null } } } })),
  )
  await POST(new NextRequest('http://localhost/api/me/sync-revenuecat', { method: 'POST' }))
  expect(mocks.rpc).toHaveBeenCalledWith(
    'apply_billing_reconciliation',
    expect.objectContaining({ p_provider: 'revenuecat', p_active: true }),
  )
})

it('does not touch the DB when the upstream RevenueCat call fails', async () => {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('down', { status: 500 })))
  const response = await POST(new NextRequest('http://localhost/api/me/sync-revenuecat', { method: 'POST' }))
  expect(response.status).toBe(502)
  expect(mocks.rpc).not.toHaveBeenCalled()
})

it('returns 500 without fabricating a plan when reconciliation fails', async () => {
  mocks.rpc.mockResolvedValue({ data: null, error: { message: 'db offline' } })
  const response = await POST(new NextRequest('http://localhost/api/me/sync-revenuecat', { method: 'POST' }))
  expect(response.status).toBe(500)
  const body = await response.json()
  expect(body.plan).toBeUndefined()
})
