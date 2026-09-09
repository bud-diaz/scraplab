import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { uuidSchema } from '@/lib/validation/identifiers'

// No .default() here: an omitted field must stay absent so the upsert RPC
// can tell "not provided, keep the existing value" apart from "explicitly
// set" — see upsert_household_inventory in migrations/013_inventory_persistence.sql.
const postSchema = z.object({
  materialId: uuidSchema,
  source: z.enum(['manual', 'detected', 'saved']).optional(),
  stapleFlag: z.boolean().optional(),
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

  const patch: Record<string, unknown> = {}
  if (parsed.data.source !== undefined) patch.source = parsed.data.source
  if (parsed.data.stapleFlag !== undefined) patch.stapleFlag = parsed.data.stapleFlag
  if (parsed.data.confidenceScore !== undefined) patch.confidenceScore = parsed.data.confidenceScore

  const db = createServiceClient()
  const { data: row, error: rpcError } = await db.rpc('upsert_household_inventory', {
    p_user_id: user.id,
    p_material_id: parsed.data.materialId,
    p_patch: patch,
  })

  if (rpcError) {
    if (rpcError.message?.includes('Household staples require ScrapLab Plus')) {
      return NextResponse.json(
        { error: 'Household staples require ScrapLab Plus', upgradeRequired: true },
        { status: 403 }
      )
    }
    return NextResponse.json({ error: rpcError.message }, { status: 500 })
  }

  const { data, error: dbError } = await db
    .from('household_inventory')
    .select('*, material:materials(*)')
    .eq('id', row.id)
    .single()

  if (dbError || !data) {
    return NextResponse.json({ error: 'Could not load inventory item' }, { status: 500 })
  }

  return NextResponse.json({ item: data }, { status: 201 })
}
