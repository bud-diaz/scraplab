import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { uuidSchema } from '@/lib/validation/identifiers'

const postSchema = z.object({
  projectId: uuidSchema,
  childProfileId: uuidSchema.optional(),
})

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const { data, error: dbError } = await db
    .from('build_history')
    .select('*, project:projects(*)')
    .eq('user_id', user.id)
    .order('started_at', { ascending: false })

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ buildHistory: data })
}

export async function POST(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  let body: unknown
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 })
  }

  const parsed = postSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }

  const db = createServiceClient()

  if (parsed.data.childProfileId) {
    const { data: childProfile } = await db
      .from('child_profiles')
      .select('id')
      .eq('id', parsed.data.childProfileId)
      .eq('user_id', user.id)
      .maybeSingle()

    if (!childProfile) {
      return NextResponse.json({ error: 'Child profile not found' }, { status: 403 })
    }
  }

  // start_or_resume_build serializes concurrent starts for the same
  // (user, project) via a DB-level unique partial index, so a retried
  // request or an effect firing twice can never create duplicate
  // 'started' rows — it resumes the existing one instead.
  const { data: buildRow, error: rpcError } = await db.rpc('start_or_resume_build', {
    p_user_id: user.id,
    p_project_id: parsed.data.projectId,
    p_child_profile_id: parsed.data.childProfileId ?? null,
  })

  if (rpcError || !buildRow) {
    return NextResponse.json({ error: rpcError?.message ?? 'Could not start build' }, { status: 500 })
  }

  const { data, error: dbError } = await db
    .from('build_history')
    .select('*, project:projects(*)')
    .eq('id', buildRow.id)
    .single()

  if (dbError || !data) {
    return NextResponse.json({ error: 'Could not load build entry' }, { status: 500 })
  }

  return NextResponse.json({ buildEntry: data }, { status: 201 })
}
