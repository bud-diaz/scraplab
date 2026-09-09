import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'

// Grants/reflects the 'plus' entitlement. 'plan_source' guards this from
// racing the Stripe webhook for the same user (see api/webhooks/stripe).
const UPGRADE_EVENT_TYPES = new Set(['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'PRODUCT_CHANGE'])
const DOWNGRADE_EVENT_TYPES = new Set(['EXPIRATION'])

export async function POST(request: NextRequest) {
  const auth = request.headers.get('authorization')
  const secret = process.env.REVENUECAT_WEBHOOK_SECRET
  if (!secret || auth !== `Bearer ${secret}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const body = await request.json()
  const event = body.event
  const userId: string | undefined = event?.app_user_id
  const eventType: string | undefined = event?.type

  if (!userId || !eventType) {
    return NextResponse.json({ error: 'Malformed event' }, { status: 400 })
  }

  const db = createServiceClient()

  if (UPGRADE_EVENT_TYPES.has(eventType)) {
    const { error } = await db
      .from('profiles')
      .update({ plan: 'plus', plan_source: 'revenuecat', revenuecat_app_user_id: userId })
      .eq('id', userId)
    if (error) {
      console.error('RevenueCat webhook: failed to upgrade plan', error)
      return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
    }
  } else if (DOWNGRADE_EVENT_TYPES.has(eventType)) {
    const { error } = await db
      .from('profiles')
      .update({ plan: 'free' })
      .eq('id', userId)
      .eq('plan_source', 'revenuecat')
    if (error) {
      console.error('RevenueCat webhook: failed to downgrade plan', error)
      return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
    }
  }

  return NextResponse.json({ received: true })
}
