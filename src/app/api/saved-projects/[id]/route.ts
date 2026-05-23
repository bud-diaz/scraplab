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

  const { error: dbError } = await db
    .from('saved_projects')
    .delete()
    .eq('id', id)
    .eq('user_id', user.id)

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 })
  }

  return new NextResponse(null, { status: 204 })
}
