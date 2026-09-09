import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const { id } = await params
  const db = createServiceClient()

  const { data, error: dbError } = await db
    .from('saved_projects')
    .delete()
    .eq('id', id)
    .eq('user_id', user.id)
    .select('id')

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  if (!data || data.length === 0) {
    return NextResponse.json({ error: 'Saved project not found' }, { status: 404 })
  }

  return new NextResponse(null, { status: 204 })
}
