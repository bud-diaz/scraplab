import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

const patchSchema = z.object({
  completionStatus: z.enum(['started', 'completed', 'abandoned']),
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

  const db = createServiceClient()
  const update: Record<string, unknown> = {
    completion_status: parsed.data.completionStatus,
  }
  if (parsed.data.completionStatus === 'completed') {
    update.completed_at = new Date().toISOString()
  }

  const { data, error: dbError } = await db
    .from('build_history')
    .update(update)
    .eq('id', id)
    .eq('user_id', user.id)
    .select('*, project:projects(*)')
    .single()

  if (dbError || !data) {
    return NextResponse.json({ error: 'Build entry not found' }, { status: 404 })
  }

  return NextResponse.json({ buildEntry: data })
}
