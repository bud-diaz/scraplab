import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ from: vi.fn(), rpc: vi.fn(), getUser: vi.fn() }))
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
  return builder
}

function request(childAge: number) {
  return new NextRequest('http://localhost/api/activity-recommendations', {
    method: 'POST',
    body: JSON.stringify({ materialIds: ['m1'], childAge }),
    headers: { 'Content-Type': 'application/json' },
  })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.getUser.mockResolvedValue(null)
  mocks.from.mockImplementation((table: string) => {
    if (table === 'materials') return chain({ data: [{ name: 'Cardboard', aliases: [] }], error: null })
    if (table === 'activities') return chain({ data: [], error: null })
    throw new Error(`unexpected table ${table}`)
  })
  mocks.rpc.mockResolvedValue({ data: { allowed: true, remaining: 2, usedToday: 1 }, error: null })
})

describe('activity-recommendations age-safety boundary (F12)', () => {
  it.each([0, 1, 2])('rejects unsupported age %i rather than silently mapping into the 3-5 bucket', async (age) => {
    const res = await POST(request(age))
    expect(res.status).toBe(400)
  })

  it.each([3, 4, 8, 18])('accepts a supported age %i', async (age) => {
    const res = await POST(request(age))
    expect(res.status).toBe(200)
  })

  it('rejects an age above the schema bound', async () => {
    const res = await POST(request(19))
    expect(res.status).toBe(400)
  })
})
