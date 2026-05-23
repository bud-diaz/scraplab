import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

const patchSchema = z.object({
  stapleFlag: z.boolean().optional(),
  source: z.enum(['manual', 'detected', 'saved']).optional(),
  confidenceScore: z.number().min(0).max(1).optional(),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const { id } = await params

  let body: unknown
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 })
  }

  const parsed = patchSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }

  const update: Record<string, unknown> = { updated_at: new Date().toISOString() }
  if (parsed.data.stapleFlag !== undefined) update.staple_flag = parsed.data.stapleFlag
  if (parsed.data.source !== undefined) update.source = parsed.data.source
  if (parsed.data.confidenceScore !== undefined) update.confidence_score = parsed.data.confidenceScore

  const db = createServiceClient()
  const { data, error: dbError } = await db
    .from('household_inventory')
    .update(update)
    .eq('id', id)
    .eq('user_id', user.id)
    .select('*, material:materials(*)')
    .single()

  if (dbError || !data) {
    return NextResponse.json({ error: 'Item not found' }, { status: 404 })
  }

  return NextResponse.json({ item: data })
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const { id } = await params
  const db = createServiceClient()

  const { error: dbError } = await db
    .from('household_inventory')
    .delete()
    .eq('id', id)
    .eq('user_id', user.id)

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return new NextResponse(null, { status: 204 })
}
