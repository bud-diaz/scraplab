import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ from: vi.fn(), rpc: vi.fn(), getUser: vi.fn(), detect: vi.fn() }))
vi.mock('@/lib/db/client', () => ({
  createServiceClient: () => ({ from: mocks.from, rpc: mocks.rpc }),
  getUserFromRequest: mocks.getUser,
}))
vi.mock('@/lib/ai/suggestions', () => ({ generateAiSuggestions: vi.fn(() => Promise.resolve([])) }))

import { POST } from '@/app/api/activity-recommendations/route'

function chain(result: { data: unknown; error: unknown }) {
  const builder: Record<string, unknown> = {}
  builder.select = vi.fn(() => builder)
  builder.eq = vi.fn(() => builder)
  builder.in = vi.fn(() => Promise.resolve(result))
  builder.overlaps = vi.fn(() => builder)
  builder.or = vi.fn(() => Promise.resolve(result))
  builder.single = vi.fn(() => Promise.resolve(result))
  return builder
}

function request(body: unknown, headers: Record<string, string> = {}) {
  return new NextRequest('http://localhost/api/activity-recommendations', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...headers },
  })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.getUser.mockResolvedValue(null)
  mocks.from.mockImplementation((table: string) => {
    if (table === 'materials') return chain({ data: [{ name: 'Cardboard', aliases: [] }], error: null })
    if (table === 'activities') return chain({ data: [], error: null })
    if (table === 'profiles') return chain({ data: { plan: 'free' }, error: null })
    throw new Error(`unexpected table ${table}`)
  })
  mocks.rpc.mockResolvedValue({ data: { allowed: true, remaining: 2, usedToday: 1 }, error: null })
})

describe('POST /api/activity-recommendations — guest/free usage limit', () => {
  it('rejects ages below the supported minimum instead of clamping upward', async () => {
    const res = await POST(request({ materialIds: ['m1'], childAge: 1 }))
    expect(res.status).toBe(400)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('reserves guest quota by a hashed IP identity, not raw materials/DB calls', async () => {
    const res = await POST(request({ materialIds: ['m1'], childAge: 6 }, { 'x-forwarded-for': '1.2.3.4' }))
    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith(
      'reserve_recommendation_usage',
      expect.objectContaining({ p_identity: expect.stringMatching(/^guest:[0-9a-f]{32}$/), p_daily_limit: 3 }),
    )
  })

  it('reserves by user identity when authenticated', async () => {
    mocks.getUser.mockResolvedValue({ id: 'user-1' })
    const res = await POST(request({ materialIds: ['m1'], childAge: 6 }))
    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith(
      'reserve_recommendation_usage',
      expect.objectContaining({ p_identity: 'user:user-1', p_daily_limit: 3 }),
    )
  })

  it('returns 429 with upgradeRequired once the reservation is denied', async () => {
    mocks.rpc.mockResolvedValue({ data: { allowed: false, remaining: 0, usedToday: 3 }, error: null })
    const res = await POST(request({ materialIds: ['m1'], childAge: 6 }))
    expect(res.status).toBe(429)
    const body = await res.json()
    expect(body.upgradeRequired).toBe(true)
  })

  it('skips the reservation entirely for a Plus user (unlimited)', async () => {
    mocks.getUser.mockResolvedValue({ id: 'user-plus' })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'materials') return chain({ data: [{ name: 'Cardboard', aliases: [] }], error: null })
      if (table === 'activities') return chain({ data: [], error: null })
      if (table === 'profiles') return chain({ data: { plan: 'plus' }, error: null })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await POST(request({ materialIds: ['m1'], childAge: 6 }))
    expect(res.status).toBe(200)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('redacts premium activity content for a free/guest caller', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'materials') return chain({ data: [{ name: 'Cardboard', aliases: [] }], error: null })
      if (table === 'activities')
        return chain({
          data: [
            {
              id: 'a1',
              materials_required: ['cardboard'],
              premium: true,
              description: 'secret sauce',
              expansion_prompts: ['secret idea'],
              learning_angle: 'secret angle',
            },
          ],
          error: null,
        })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await POST(request({ materialIds: ['m1'], childAge: 6 }))
    const body = await res.json()
    expect(body.matches[0].activity.description).toBeNull()
    expect(body.matches[0].activity.previewOnly).toBe(true)
  })
})
