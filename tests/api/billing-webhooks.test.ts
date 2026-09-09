import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({
  from: vi.fn(),
  rpc: vi.fn(),
  constructEvent: vi.fn(),
}))

vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: mocks.from, rpc: mocks.rpc }) }))
vi.mock('@/lib/stripe', () => ({ getStripe: () => ({ webhooks: { constructEvent: mocks.constructEvent } }) }))

function chain(overrides: Record<string, unknown> = {}) {
  const builder: Record<string, unknown> = {
    select: vi.fn(() => builder),
    eq: vi.fn(() => builder),
    update: vi.fn(() => builder),
    insert: vi.fn(() => Promise.resolve({ error: null })),
    maybeSingle: vi.fn(() => Promise.resolve({ data: null, error: null })),
    then: undefined,
    ...overrides,
  }
  return builder
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.rpc.mockResolvedValue({ data: { status: 'applied', plan: 'plus' }, error: null })
})

describe('POST /api/webhooks/revenuecat', () => {
  const authHeaders = (secret = 'rc-secret') => ({ authorization: `Bearer ${secret}`, 'content-type': 'application/json' })

  beforeEach(() => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', 'rc-secret')
  })

  async function post(body: unknown, headers = authHeaders()) {
    const { POST } = await import('@/app/api/webhooks/revenuecat/route')
    return POST(
      new NextRequest('http://localhost/api/webhooks/revenuecat', {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
      }),
    )
  }

  it('rejects requests without a matching bearer secret', async () => {
    const res = await post({ event: {} }, authHeaders('wrong'))
    expect(res.status).toBe(401)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('rejects malformed events missing app_user_id/type', async () => {
    mocks.from.mockReturnValue(chain())
    const res = await post({ event: { id: 'evt_1' } })
    expect(res.status).toBe(400)
  })

  it('skips reprocessing a duplicate event id', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain({ insert: vi.fn(() => Promise.resolve({ error: { code: '23505' } })) })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await post({ event: { id: 'evt_dup', app_user_id: 'user-1', type: 'INITIAL_PURCHASE', entitlement_ids: ['plus'] } })
    expect((await res.json()).duplicate).toBe(true)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('ignores events for an entitlement other than plus', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      throw new Error(`unexpected table ${table}`)
    })
    const res = await post({ event: { id: 'evt_2', app_user_id: 'user-1', type: 'INITIAL_PURCHASE', entitlement_ids: ['some_other_product'] } })
    expect((await res.json()).ignored).toBe(true)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('grants plus on an upgrade event for the plus entitlement', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      if (table === 'profiles') return chain({ update: vi.fn(() => chain()) })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await post({ event: { id: 'evt_3', app_user_id: 'user-1', type: 'RENEWAL', entitlement_ids: ['plus'] } })
    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('apply_billing_reconciliation', expect.objectContaining({ p_provider: 'revenuecat', p_active: true }))
  })

  it('acknowledges without retrying when the profile does not exist', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      throw new Error(`unexpected table ${table}`)
    })
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'Profile not found for user user-1' } })
    const res = await post({ event: { id: 'evt_4', app_user_id: 'user-1', type: 'EXPIRATION', entitlement_ids: ['plus'] } })
    expect(res.status).toBe(200)
    expect((await res.json()).skipped).toBe(true)
  })
})

describe('POST /api/webhooks/stripe', () => {
  beforeEach(() => {
    vi.stubEnv('STRIPE_WEBHOOK_SECRET', 'whsec_test')
  })

  async function post(rawBody = '{}') {
    const { POST } = await import('@/app/api/webhooks/stripe/route')
    return POST(
      new NextRequest('http://localhost/api/webhooks/stripe', {
        method: 'POST',
        headers: { 'stripe-signature': 't=1,v1=fake' },
        body: rawBody,
      }),
    )
  }

  it('rejects a request with no stripe-signature header', async () => {
    const { POST } = await import('@/app/api/webhooks/stripe/route')
    const res = await POST(new NextRequest('http://localhost/api/webhooks/stripe', { method: 'POST', body: '{}' }))
    expect(res.status).toBe(400)
  })

  it('rejects an invalid signature', async () => {
    mocks.constructEvent.mockImplementation(() => {
      throw new Error('bad signature')
    })
    const res = await post()
    expect(res.status).toBe(400)
  })

  it('skips reprocessing a duplicate stripe event id', async () => {
    mocks.constructEvent.mockReturnValue({ id: 'evt_dup', type: 'checkout.session.completed', created: 1000, data: { object: {} } })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain({ insert: vi.fn(() => Promise.resolve({ error: { code: '23505' } })) })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await post()
    expect((await res.json()).duplicate).toBe(true)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('grants plus and stores the customer id on checkout.session.completed', async () => {
    mocks.constructEvent.mockReturnValue({
      id: 'evt_1',
      type: 'checkout.session.completed',
      created: 1000,
      data: { object: { client_reference_id: 'user-1', customer: 'cus_1' } },
    })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      if (table === 'profiles') return chain({ update: vi.fn(() => chain()) })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await post()
    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('apply_billing_reconciliation', expect.objectContaining({ p_provider: 'stripe', p_active: true }))
  })

  it('keeps access active on a past_due subscription.updated event', async () => {
    mocks.constructEvent.mockReturnValue({
      id: 'evt_2',
      type: 'customer.subscription.updated',
      created: 1000,
      data: { object: { customer: 'cus_1', status: 'past_due' } },
    })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      if (table === 'profiles') return chain({ maybeSingle: vi.fn(() => Promise.resolve({ data: { id: 'user-1' }, error: null })) })
      throw new Error(`unexpected table ${table}`)
    })
    await post()
    expect(mocks.rpc).toHaveBeenCalledWith('apply_billing_reconciliation', expect.objectContaining({ p_provider: 'stripe', p_active: true }))
  })

  it('revokes access on customer.subscription.deleted', async () => {
    mocks.constructEvent.mockReturnValue({
      id: 'evt_3',
      type: 'customer.subscription.deleted',
      created: 1000,
      data: { object: { customer: 'cus_1', status: 'canceled' } },
    })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      if (table === 'profiles') return chain({ maybeSingle: vi.fn(() => Promise.resolve({ data: { id: 'user-1' }, error: null })) })
      throw new Error(`unexpected table ${table}`)
    })
    await post()
    expect(mocks.rpc).toHaveBeenCalledWith('apply_billing_reconciliation', expect.objectContaining({ p_provider: 'stripe', p_active: false }))
  })

  it('does not error when no profile matches the customer id', async () => {
    mocks.constructEvent.mockReturnValue({
      id: 'evt_4',
      type: 'customer.subscription.deleted',
      created: 1000,
      data: { object: { customer: 'cus_unknown', status: 'canceled' } },
    })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'billing_webhook_events') return chain()
      if (table === 'profiles') return chain({ maybeSingle: vi.fn(() => Promise.resolve({ data: null, error: null })) })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await post()
    expect(res.status).toBe(200)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
})
