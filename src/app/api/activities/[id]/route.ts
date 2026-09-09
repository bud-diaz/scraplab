import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { isSafeRouteSegment } from '@/lib/validation/identifiers'

export async function GET(
  _request: NextRequest,
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

  return NextResponse.json({ activity: data })
}
