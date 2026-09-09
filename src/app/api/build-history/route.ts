import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

const postSchema = z.object({
  projectId: z.string().uuid(),
  childProfileId: z.string().uuid().optional(),
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

  const { data, error: dbError } = await db
    .from('build_history')
    .insert({
      user_id: user.id,
      project_id: parsed.data.projectId,
      child_profile_id: parsed.data.childProfileId ?? null,
      completion_status: 'started',
    })
    .select('*, project:projects(*)')
    .single()

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ buildEntry: data }, { status: 201 })
}
