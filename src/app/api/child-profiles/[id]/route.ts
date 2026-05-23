import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

const patchSchema = z.object({
  name: z.string().max(100).nullable().optional(),
  age: z.number().int().min(0).max(18).optional(),
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

  const update: Record<string, unknown> = {}
  if (parsed.data.name !== undefined) update.name = parsed.data.name
  if (parsed.data.age !== undefined) update.age = parsed.data.age

  if (Object.keys(update).length === 0) {
    return NextResponse.json({ error: 'No fields to update' }, { status: 400 })
  }

  const db = createServiceClient()
  const { data, error: dbError } = await db
    .from('child_profiles')
    .update(update)
    .eq('id', id)
    .eq('user_id', user.id)
    .select()
    .single()

  if (dbError || !data) {
    return NextResponse.json({ error: 'Child profile not found' }, { status: 404 })
  }

  return NextResponse.json({ childProfile: data })
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
    .from('child_profiles')
    .delete()
    .eq('id', id)
    .eq('user_id', user.id)

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return new NextResponse(null, { status: 204 })
}
