import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ auth: vi.fn(), from: vi.fn(), rpc: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: mocks.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: mocks.from, rpc: mocks.rpc }) }))

import { POST } from '@/app/api/build-history/route'
import { PATCH } from '@/app/api/build-history/[id]/route'

const PROJECT_ID = '33333333-3333-4333-8333-333333333333'
const BUILD_ID = '44444444-4444-4444-8444-444444444444'

function chain(result: { data: unknown; error: unknown }) {
  const builder: Record<string, unknown> = {}
  builder.select = vi.fn(() => builder)
  builder.eq = vi.fn(() => builder)
  builder.single = vi.fn(() => Promise.resolve(result))
  return builder
}

function postRequest(body: unknown) {
  return new NextRequest('http://localhost/api/build-history', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  })
}

function patchRequest(body: unknown) {
  return new NextRequest(`http://localhost/api/build-history/${BUILD_ID}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.auth.mockResolvedValue({ user: { id: 'user-1' }, error: null })
})

describe('POST /api/build-history (start/resume)', () => {
  it('starts a build and returns the entry with current_step', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: BUILD_ID }, error: null })
    mocks.from.mockReturnValue(chain({ data: { id: BUILD_ID, current_step: 0, completion_status: 'started' }, error: null }))

    const res = await POST(postRequest({ projectId: PROJECT_ID }))
    expect(res.status).toBe(201)
    const body = await res.json()
    expect(body.buildEntry.current_step).toBe(0)
  })

  it('resuming an in-progress build returns its existing current_step, not step 0', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: BUILD_ID }, error: null })
    mocks.from.mockReturnValue(chain({ data: { id: BUILD_ID, current_step: 3, completion_status: 'started' }, error: null }))

    const res = await POST(postRequest({ projectId: PROJECT_ID }))
    const body = await res.json()
    expect(body.buildEntry.current_step).toBe(3)
  })
})

describe('PATCH /api/build-history/[id] (progress/pause/complete)', () => {
  it('rejects a body with neither completionStatus nor currentStep', async () => {
    const res = await PATCH(patchRequest({}), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(400)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })

  it('persists a step advance', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: BUILD_ID }, error: null })
    mocks.from.mockReturnValue(chain({ data: { id: BUILD_ID, current_step: 2 }, error: null }))

    const res = await PATCH(patchRequest({ currentStep: 2 }), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith(
      'update_build_progress',
      expect.objectContaining({ p_build_id: BUILD_ID, p_current_step: 2, p_completion_status: null }),
    )
  })

  it('pauses via completionStatus: abandoned', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: BUILD_ID }, error: null })
    mocks.from.mockReturnValue(chain({ data: { id: BUILD_ID, completion_status: 'abandoned' }, error: null }))

    const res = await PATCH(patchRequest({ completionStatus: 'abandoned' }), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(200)
  })

  it('maps "Finish the last step first" to 400', async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'Finish the last step first' } })
    const res = await PATCH(patchRequest({ completionStatus: 'completed' }), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(400)
  })

  it('maps "Terminal build cannot change" to 409', async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'Terminal build cannot change' } })
    const res = await PATCH(patchRequest({ completionStatus: 'started' }), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(409)
  })

  it('maps "Build not found" (wrong owner or bad id) to 404', async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'Build not found' } })
    const res = await PATCH(patchRequest({ currentStep: 1 }), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(404)
  })

  it('repeated completion is idempotent (200, not an error)', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: BUILD_ID }, error: null })
    mocks.from.mockReturnValue(
      chain({ data: { id: BUILD_ID, completion_status: 'completed', completed_at: '2026-01-01T00:00:00Z' }, error: null }),
    )
    const res = await PATCH(patchRequest({ completionStatus: 'completed' }), { params: Promise.resolve({ id: BUILD_ID }) })
    expect(res.status).toBe(200)
  })
})
