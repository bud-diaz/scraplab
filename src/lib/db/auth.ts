import { NextRequest, NextResponse } from 'next/server'
import { getUserFromRequest, createServiceClient } from './client'
import type { User } from '@supabase/supabase-js'

export async function requireAuth(
  request: NextRequest
): Promise<{ user: User; error: null } | { user: null; error: NextResponse }> {
  const user = await getUserFromRequest(request)
  if (!user) {
    return {
      user: null,
      error: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }),
    }
  }
  return { user, error: null }
}

export async function getOrCreateProfile(userId: string, email: string) {
  const db = createServiceClient()
  const { data } = await db
    .from('profiles')
    .upsert({ id: userId, email }, { onConflict: 'id', ignoreDuplicates: true })
    .select()
    .single()
  return data
}
