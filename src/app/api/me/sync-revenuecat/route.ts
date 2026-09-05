import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/db/auth'
import { createServiceClient } from '@/lib/db/client'

// Called right after a successful client-side RevenueCat purchase, so the
// UI reflects the new plan immediately instead of waiting on the async
// RevenueCat webhook. Authoritative check happens server-side against
// RevenueCat's API — the client-reported purchase result is never trusted
// directly for the DB write.
export async function POST(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const apiKey = process.env.REVENUECAT_SECRET_API_KEY
  if (!apiKey) {
    return NextResponse.json({ error: 'RevenueCat is not configured' }, { status: 503 })
  }

  const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${user.id}`, {
    headers: { Authorization: `Bearer ${apiKey}` },
  })
  if (!res.ok) {
    return NextResponse.json({ error: 'Could not verify subscription status' }, { status: 502 })
  }

  const data = await res.json()
  const expiresAt: string | null = data.subscriber?.entitlements?.plus?.expires_date ?? null
  const isPlus = expiresAt === null || new Date(expiresAt) > new Date()
  const hasEntitlement = 'plus' in (data.subscriber?.entitlements ?? {})

  const db = createServiceClient()
  const plan = hasEntitlement && isPlus ? 'plus' : 'free'
  const { error: updateError } = await db
    .from('profiles')
    .update({ plan, plan_source: 'revenuecat', revenuecat_app_user_id: user.id })
    .eq('id', user.id)

  if (updateError) {
    return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
  }

  return NextResponse.json({ plan })
}
