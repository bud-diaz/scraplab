import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, isWithinLimit } from '@/lib/access'

const postSchema = z.object({
  name: z.string().max(100).nullable().optional(),
  age: z.number().int().min(0).max(18),
})

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const { data, error: dbError } = await db
    .from('child_profiles')
    .select('*')
    .eq('user_id', user.id)
    .order('created_at')

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ childProfiles: data })
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

  const { count } = await db
    .from('child_profiles')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)

  if (!isWithinLimit(plan, 'childProfiles', count ?? 0)) {
    return NextResponse.json(
      { error: 'Child profile limit reached', upgradeRequired: true },
      { status: 429 }
    )
  }

  const { data, error: dbError } = await db
    .from('child_profiles')
    .insert({ user_id: user.id, name: parsed.data.name ?? null, age: parsed.data.age })
    .select()
    .single()

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ childProfile: data }, { status: 201 })
}
