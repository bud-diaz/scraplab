import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { claimWebhookEvent, reconcileEntitlement } from '@/lib/billing/entitlements'

// Grants/reflects the 'plus' entitlement independently of Stripe — see
// src/lib/billing/entitlements.ts. Events for an entitlement other than
// 'plus' (e.g. a future add-on product) are acknowledged but ignored.
const UPGRADE_EVENT_TYPES = new Set(['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'PRODUCT_CHANGE'])
const DOWNGRADE_EVENT_TYPES = new Set(['EXPIRATION'])
const PLUS_ENTITLEMENT_ID = 'plus'

export async function POST(request: NextRequest) {
  const auth = request.headers.get('authorization')
  const secret = process.env.REVENUECAT_WEBHOOK_SECRET
  if (!secret || auth !== `Bearer ${secret}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  let body: { event?: Record<string, unknown> }
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Malformed event' }, { status: 400 })
  }

  const event = body.event
  const userId = typeof event?.app_user_id === 'string' ? event.app_user_id : undefined
  const eventType = typeof event?.type === 'string' ? event.type : undefined
  const eventId = typeof event?.id === 'string' ? event.id : undefined

  if (!userId || !eventType) {
    return NextResponse.json({ error: 'Malformed event' }, { status: 400 })
  }

  const db = createServiceClient()

  if (eventId) {
    const isNew = await claimWebhookEvent(db, 'revenuecat', eventId)
    if (!isNew) {
      return NextResponse.json({ received: true, duplicate: true })
    }
  }

  const isUpgrade = UPGRADE_EVENT_TYPES.has(eventType)
  const isDowngrade = DOWNGRADE_EVENT_TYPES.has(eventType)

  if (isUpgrade || isDowngrade) {
    const entitlementIds = Array.isArray(event?.entitlement_ids)
      ? (event.entitlement_ids as unknown[]).filter((id): id is string => typeof id === 'string')
      : typeof event?.entitlement_id === 'string'
        ? [event.entitlement_id]
        : null

    // Only act if we can confirm this event is about the 'plus'
    // entitlement — an unrecognized/absent entitlement list means we
    // can't safely tell, so skip rather than guess.
    if (entitlementIds !== null && !entitlementIds.includes(PLUS_ENTITLEMENT_ID)) {
      return NextResponse.json({ received: true, ignored: true })
    }

    const eventTimeMs = typeof event?.event_timestamp_ms === 'number' ? event.event_timestamp_ms : undefined
    const eventTime = eventTimeMs ? new Date(eventTimeMs) : undefined

    try {
      await reconcileEntitlement(db, userId, 'revenuecat', isUpgrade, eventTime)
    } catch (err) {
      if (err instanceof Error && err.message.includes('Profile not found')) {
        // Permanent failure (deleted/nonexistent account) — retrying won't
        // help, so acknowledge instead of causing indefinite webhook retries.
        console.warn('RevenueCat webhook: no profile for user', userId)
        return NextResponse.json({ received: true, skipped: true })
      }
      console.error('RevenueCat webhook: reconciliation failed', err)
      return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
    }

    if (isUpgrade) {
      await db.from('profiles').update({ revenuecat_app_user_id: userId }).eq('id', userId)
    }
  }

  return NextResponse.json({ received: true })
}
