import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient, getUserFromRequest } from '@/lib/db/client'
import { isSafeRouteSegment } from '@/lib/validation/identifiers'
import { getUserPlan, redactPremiumActivity } from '@/lib/access'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params

  if (!isSafeRouteSegment(id)) {
    return NextResponse.json({ error: 'Activity not found' }, { status: 404 })
  }

  const db = createServiceClient()

  // Support lookup by either slug or id
  const { data, error } = await db
    .from('activities')
    .select('*')
    .or(`id.eq.${id},slug.eq.${id}`)
    .single()

  if (error || !data) {
    return NextResponse.json({ error: 'Activity not found' }, { status: 404 })
  }

  const user = await getUserFromRequest(request)
  const plan = user ? await getUserPlan(db, user.id) : 'free'

  return NextResponse.json({ activity: redactPremiumActivity(plan, data) })
}
