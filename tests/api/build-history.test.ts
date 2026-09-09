import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ auth: vi.fn(), from: vi.fn(), rpc: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: mocks.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: mocks.from, rpc: mocks.rpc }) }))

import { POST } from '@/app/api/build-history/route'

const OWN_CHILD = '11111111-1111-4111-8111-111111111111'
const OTHER_CHILD = '22222222-2222-4222-8222-222222222222'
const PROJECT_ID = '33333333-3333-4333-8333-333333333333'

function chain(result: { data: unknown; error: unknown }) {
  const builder: Record<string, unknown> = {}
  builder.select = vi.fn(() => builder)
  builder.eq = vi.fn(() => builder)
  builder.insert = vi.fn(() => builder)
  builder.maybeSingle = vi.fn(() => Promise.resolve(result))
  builder.single = vi.fn(() => Promise.resolve(result))
  return builder
}

function request(body: unknown) {
  return new NextRequest('http://localhost/api/build-history', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.auth.mockResolvedValue({ user: { id: 'user-1' }, error: null })
})

describe('POST /api/build-history child profile ownership', () => {
  it('rejects a childProfileId that does not belong to the caller', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'child_profiles') return chain({ data: null, error: null })
      throw new Error(`unexpected table ${table}`)
    })

    const response = await POST(request({ projectId: PROJECT_ID, childProfileId: OTHER_CHILD }))

    expect(response.status).toBe(403)
    expect(mocks.from).toHaveBeenCalledWith('child_profiles')
    expect(mocks.from).not.toHaveBeenCalledWith('build_history')
  })

  it('creates/resumes a build_history row when the caller owns the child profile', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: 'bh-1' }, error: null })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'child_profiles') return chain({ data: { id: OWN_CHILD }, error: null })
      if (table === 'build_history')
        return chain({ data: { id: 'bh-1', project_id: PROJECT_ID, child_profile_id: OWN_CHILD }, error: null })
      throw new Error(`unexpected table ${table}`)
    })

    const response = await POST(request({ projectId: PROJECT_ID, childProfileId: OWN_CHILD }))

    expect(response.status).toBe(201)
    expect(mocks.from).toHaveBeenCalledWith('child_profiles')
    expect(mocks.rpc).toHaveBeenCalledWith(
      'start_or_resume_build',
      expect.objectContaining({ p_project_id: PROJECT_ID, p_child_profile_id: OWN_CHILD }),
    )
  })

  it('skips the ownership check when no childProfileId is supplied', async () => {
    mocks.rpc.mockResolvedValue({ data: { id: 'bh-1' }, error: null })
    mocks.from.mockImplementation((table: string) => {
      if (table === 'build_history') return chain({ data: { id: 'bh-1', project_id: PROJECT_ID }, error: null })
      throw new Error(`unexpected table ${table}`)
    })

    const response = await POST(request({ projectId: PROJECT_ID }))

    expect(response.status).toBe(201)
    expect(mocks.from).not.toHaveBeenCalledWith('child_profiles')
  })

  it('returns 500 without creating a row if the resume RPC fails', async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: 'db offline' } })
    const response = await POST(request({ projectId: PROJECT_ID }))
    expect(response.status).toBe(500)
    expect(mocks.from).not.toHaveBeenCalledWith('build_history')
  })
})
