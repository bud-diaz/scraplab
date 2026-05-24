import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan } from '@/lib/access'

function pickRandom<T>(arr: T[], n: number): T[] {
  const shuffled = [...arr].sort(() => Math.random() - 0.5)
  return shuffled.slice(0, n)
}

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const plan = await getUserPlan(db, user.id)

  if (plan !== 'plus') {
    return NextResponse.json(
      { error: 'Mystery Build requires ScrapLab Plus', upgradeRequired: true },
      { status: 403 }
    )
  }

  // Try user's household inventory first
  const { data: inventory } = await db
    .from('household_inventory')
    .select('material_id')
    .eq('user_id', user.id)

  const inventoryIds = (inventory ?? []).map(r => r.material_id)

  let pickedIds: string[]

  if (inventoryIds.length >= 3) {
    pickedIds = pickRandom(inventoryIds, 3)
  } else {
    // Fall back to random from full materials list
    const { data: allMaterials } = await db
      .from('materials')
      .select('id')
    const allIds = (allMaterials ?? []).map(r => r.id)
    // Start with whatever inventory items exist, fill the rest randomly
    const remaining = allIds.filter(id => !inventoryIds.includes(id))
    pickedIds = [...inventoryIds, ...pickRandom(remaining, 3 - inventoryIds.length)]
  }

  // Fetch full material details
  const { data: materials } = await db
    .from('materials')
    .select('id, name, icon, category')
    .in('id', pickedIds)

  return NextResponse.json({ materials: materials ?? [] })
}
