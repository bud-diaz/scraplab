import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

const patchSchema = z
  .object({
    completionStatus: z.enum(['started', 'completed', 'abandoned']).optional(),
    currentStep: z.number().int().min(0).optional(),
  })
  .refine((v) => v.completionStatus !== undefined || v.currentStep !== undefined, {
    message: 'Provide completionStatus and/or currentStep',
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

  const { data: buildRow, error: rpcError } = await db.rpc('update_build_progress', {
    p_build_id: id,
    p_user_id: user.id,
    p_current_step: parsed.data.currentStep ?? null,
    p_completion_status: parsed.data.completionStatus ?? null,
  })

  if (rpcError) {
    const message = rpcError.message ?? ''
    if (message.includes('Build not found')) {
      return NextResponse.json({ error: 'Build entry not found' }, { status: 404 })
    }
    if (message.includes('Terminal build cannot change')) {
      return NextResponse.json({ error: 'This build is already finished' }, { status: 409 })
    }
    if (message.includes('Finish the last step first')) {
      return NextResponse.json({ error: 'Finish the last step before completing' }, { status: 400 })
    }
    return NextResponse.json({ error: message || 'Could not update build' }, { status: 500 })
  }

  if (!buildRow) {
    return NextResponse.json({ error: 'Build entry not found' }, { status: 404 })
  }

  const { data, error: dbError } = await db
    .from('build_history')
    .select('*, project:projects(*)')
    .eq('id', buildRow.id)
    .single()

  if (dbError || !data) {
    return NextResponse.json({ error: 'Could not load build entry' }, { status: 500 })
  }

  return NextResponse.json({ buildEntry: data })
}
