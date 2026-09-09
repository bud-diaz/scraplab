import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const mocks = vi.hoisted(() => ({ auth: vi.fn(), from: vi.fn(), detect: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: mocks.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: mocks.from }) }))
vi.mock('@/lib/ai/vision', () => ({ detectMaterialsFromImage: mocks.detect }))

import { POST } from '@/app/api/scan-materials/route'

function chain(result: unknown) {
  const builder: Record<string, unknown> = {}
  builder.select = vi.fn(() => builder)
  builder.eq = vi.fn(() => builder)
  builder.order = vi.fn(() => Promise.resolve(result))
  builder.single = vi.fn(() => Promise.resolve(result))
  return builder
}

function multipartRequest(file: File | string | null) {
  const formData = new FormData()
  if (file !== null) formData.append('image', file)
  return new NextRequest('http://localhost/api/scan-materials', { method: 'POST', body: formData })
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.auth.mockResolvedValue({ user: { id: 'user-1' }, error: null })
  mocks.from.mockImplementation((table: string) => {
    if (table === 'profiles') return chain({ data: { plan: 'plus' }, error: null })
    if (table === 'materials') return chain({ data: [{ id: 'm1', name: 'Cardboard', aliases: [] }], error: null })
    throw new Error(`unexpected table ${table}`)
  })
  mocks.detect.mockResolvedValue([])
})

describe('POST /api/scan-materials', () => {
  it('requires Plus', async () => {
    mocks.from.mockImplementation((table: string) => {
      if (table === 'profiles') return chain({ data: { plan: 'free' }, error: null })
      throw new Error(`unexpected table ${table}`)
    })
    const res = await POST(multipartRequest(new File(['x'], 'a.jpg', { type: 'image/jpeg' })))
    expect(res.status).toBe(403)
  })

  it('rejects non-multipart content types with 415', async () => {
    const res = await POST(
      new NextRequest('http://localhost/api/scan-materials', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ imageUrl: 'http://169.254.169.254/latest/meta-data/' }),
      }),
    )
    expect(res.status).toBe(415)
    expect(mocks.detect).not.toHaveBeenCalled()
  })

  it('rejects a multipart string masquerading as a file', async () => {
    const res = await POST(multipartRequest('not-a-file'))
    expect(res.status).toBe(400)
  })

  it('rejects an empty file', async () => {
    const res = await POST(multipartRequest(new File([], 'empty.jpg', { type: 'image/jpeg' })))
    expect(res.status).toBe(400)
  })

  it('rejects a file over the size limit', async () => {
    const big = new Uint8Array(5 * 1024 * 1024 + 1)
    const res = await POST(multipartRequest(new File([big], 'big.jpg', { type: 'image/jpeg' })))
    expect(res.status).toBe(413)
  })

  it('rejects a disallowed MIME type', async () => {
    const res = await POST(multipartRequest(new File(['x'], 'a.svg', { type: 'image/svg+xml' })))
    expect(res.status).toBe(415)
  })

  it('accepts a valid image and returns detected materials', async () => {
    mocks.detect.mockResolvedValue([{ materialId: 'm1', label: 'Cardboard', confidence: 0.9 }])
    const res = await POST(multipartRequest(new File(['x'], 'a.jpg', { type: 'image/jpeg' })))
    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.detectedMaterials).toEqual([{ materialId: 'm1', label: 'Cardboard', confidence: 0.9 }])
    expect(mocks.detect).toHaveBeenCalledWith(expect.any(String), 'image/jpeg', expect.any(Array))
  })
})
