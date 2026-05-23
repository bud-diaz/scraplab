import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

const postSchema = z.object({
  materialId: z.string().uuid(),
  source: z.enum(['manual', 'detected', 'saved']).default('manual'),
  stapleFlag: z.boolean().default(false),
  confidenceScore: z.number().min(0).max(1).optional(),
})

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const { data, error: dbError } = await db
    .from('household_inventory')
    .select('*, material:materials(*)')
    .eq('user_id', user.id)
    .order('updated_at', { ascending: false })

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ inventory: data })
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
  const { data, error: dbError } = await db
    .from('household_inventory')
    .upsert(
      {
        user_id: user.id,
        material_id: parsed.data.materialId,
        source: parsed.data.source,
        staple_flag: parsed.data.stapleFlag,
        confidence_score: parsed.data.confidenceScore ?? null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,material_id' }
    )
    .select('*, material:materials(*)')
    .single()

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return NextResponse.json({ item: data }, { status: 201 })
}
