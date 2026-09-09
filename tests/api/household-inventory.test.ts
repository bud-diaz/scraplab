import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ auth: vi.fn(), from: vi.fn(), rpc: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: mocks.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: mocks.from, rpc: mocks.rpc }) }))

import { POST } from '@/app/api/household-inventory/route'

const MATERIAL_ID = '00000000-0000-0000-0000-000000000001'
const ROW_ID = '10000000-0000-0000-0000-000000000099'

function chain(result: { data: unknown; error: unknown }) {
  const builder: Record<string, unknown> = {}
  builder.select = vi.fn(() => builder)
  builder.eq = vi.fn(() => builder)
  builder.single = vi.fn(() => Promise.resolve(result))
  return builder
}

function request(body: unknown) {
  return new NextRequest('http://localhost/api/household-inventory', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.auth.mockResolvedValue({ user: { id: 'user-1' }, error: null })
})

describe('POST /api/household-inventory', () => {
  it('sends only explicitly-provided fields as the patch, omitting the rest', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: ROW_ID }, error: null })
    mocks.from.mockReturnValue(chain({ data: { id: ROW_ID }, error: null }))

    await POST(request({ materialId: MATERIAL_ID }))

    expect(mocks.rpc).toHaveBeenCalledWith('upsert_household_inventory', {
      p_user_id: 'user-1',
      p_material_id: MATERIAL_ID,
      p_patch: {},
    })
  })

  it('includes only the fields the caller actually sent', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: ROW_ID }, error: null })
    mocks.from.mockReturnValue(chain({ data: { id: ROW_ID }, error: null }))

    await POST(request({ materialId: MATERIAL_ID, stapleFlag: true }))

    expect(mocks.rpc).toHaveBeenCalledWith('upsert_household_inventory', {
      p_user_id: 'user-1',
      p_material_id: MATERIAL_ID,
      p_patch: { stapleFlag: true },
    })
  })

  it('maps the Plus-required staple error to 403 with upgradeRequired', async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'Household staples require ScrapLab Plus' } })
    const res = await POST(request({ materialId: MATERIAL_ID, stapleFlag: true }))
    expect(res.status).toBe(403)
    const body = await res.json()
    expect(body.upgradeRequired).toBe(true)
  })
})
