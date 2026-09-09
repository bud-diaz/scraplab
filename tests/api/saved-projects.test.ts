import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ auth: vi.fn(), from: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: mocks.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: mocks.from }) }))

import { POST } from '@/app/api/saved-projects/route'
import { DELETE } from '@/app/api/saved-projects/[id]/route'

const PROJECT_ID = '10000000-0000-0000-0000-000000000001'
const SAVED_ID = '20000000-0000-0000-0000-000000000001'

function chain(overrides: Record<string, unknown> = {}) {
  const builder: Record<string, unknown> = {
    select: vi.fn(() => builder),
    eq: vi.fn(() => builder),
    insert: vi.fn(() => builder),
    delete: vi.fn(() => builder),
    single: vi.fn(() => Promise.resolve({ data: null, error: null })),
    ...overrides,
  }
  return builder
}

function postRequest(body: unknown) {
  return new NextRequest('http://localhost/api/saved-projects', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  })
}

function deleteRequest() {
  return new NextRequest('http://localhost/api/saved-projects/x', { method: 'DELETE' })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.auth.mockResolvedValue({ user: { id: 'user-1' }, error: null })
})

describe('POST /api/saved-projects', () => {
  it('rejects a non-UUID projectId (e.g. a mock/sample slug)', async () => {
    const res = await POST(postRequest({ projectId: 'cardboard-rocket' }))
    expect(res.status).toBe(400)
    expect(mocks.from).not.toHaveBeenCalled()
  })

  function mockSavedProjectsPost(opts: {
    plan: 'free' | 'plus'
    count: number
    insertResult: { data: unknown; error: unknown }
  }) {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'profiles') return chain({ single: vi.fn(() => Promise.resolve({ data: { plan: opts.plan }, error: null })) })
      if (table === 'saved_projects') {
        return {
          select: vi.fn(() => ({ eq: vi.fn(() => Promise.resolve({ count: opts.count })) })),
          insert: vi.fn(() => ({
            select: vi.fn(() => ({ single: vi.fn(() => Promise.resolve(opts.insertResult)) })),
          })),
        }
      }
      throw new Error(`unexpected table ${table}`)
    })
  }

  it('accepts a seed-style UUID and returns the saved record', async () => {
    mockSavedProjectsPost({
      plan: 'free',
      count: 0,
      insertResult: { data: { id: SAVED_ID, project_id: PROJECT_ID }, error: null },
    })

    const res = await POST(postRequest({ projectId: PROJECT_ID }))
    expect(res.status).toBe(201)
    const body = await res.json()
    expect(body.savedProject.id).toBe(SAVED_ID)
  })

  it('returns 429 with upgradeRequired at the free plan cap', async () => {
    mockSavedProjectsPost({ plan: 'free', count: 10, insertResult: { data: null, error: null } })

    const res = await POST(postRequest({ projectId: PROJECT_ID }))
    expect(res.status).toBe(429)
    const body = await res.json()
    expect(body.upgradeRequired).toBe(true)
  })

  it('treats a duplicate save as 409, not a hard failure', async () => {
    mockSavedProjectsPost({
      plan: 'plus',
      count: 5,
      insertResult: { data: null, error: { code: '23505', message: 'duplicate' } },
    })

    const res = await POST(postRequest({ projectId: PROJECT_ID }))
    expect(res.status).toBe(409)
  })
})

function mockSavedProjectsDelete(result: { data: unknown; error: unknown }) {
  const builder: Record<string, unknown> = {}
  builder.delete = vi.fn(() => builder)
  builder.eq = vi.fn(() => builder)
  builder.select = vi.fn(() => Promise.resolve(result))
  mocks.from.mockReturnValue(builder)
}

describe('DELETE /api/saved-projects/[id]', () => {
  it('returns 404 when no row matches (already unsaved, wrong owner, or nonexistent)', async () => {
    mockSavedProjectsDelete({ data: [], error: null })
    const res = await DELETE(deleteRequest(), { params: Promise.resolve({ id: SAVED_ID }) })
    expect(res.status).toBe(404)
  })

  it('returns 204 when a row is actually removed', async () => {
    mockSavedProjectsDelete({ data: [{ id: SAVED_ID }], error: null })
    const res = await DELETE(deleteRequest(), { params: Promise.resolve({ id: SAVED_ID }) })
    expect(res.status).toBe(204)
  })
})
