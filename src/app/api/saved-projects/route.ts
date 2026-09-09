import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, isWithinLimit } from '@/lib/access'
import { uuidSchema } from '@/lib/validation/identifiers'

const postSchema = z.object({
  projectId: uuidSchema,
})

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const { data, error: dbError } = await db
    .from('saved_projects')
    .select('*, project:projects(*)')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false })

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ savedProjects: data })
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
  const plan = await getUserPlan(db, user.id)

  // Check saved project limit
  const { count } = await db
    .from('saved_projects')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)

  if (!isWithinLimit(plan, 'savedProjects', count ?? 0)) {
    return NextResponse.json(
      { error: 'Saved project limit reached', upgradeRequired: true },
      { status: 429 }
    )
  }

  const { data, error: dbError } = await db
    .from('saved_projects')
    .insert({ user_id: user.id, project_id: parsed.data.projectId })
    .select('*, project:projects(*)')
    .single()

  if (dbError) {
    if (dbError.code === '23505') {
      return NextResponse.json({ error: 'Project already saved' }, { status: 409 })
    }
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ savedProject: data }, { status: 201 })
}
