import type { SupabaseClient } from '@supabase/supabase-js'

export type BillingProvider = 'stripe' | 'revenuecat'
export type Plan = 'free' | 'plus'

export interface ReconciliationResult {
  status: 'applied' | 'stale'
  plan: Plan
}

/**
 * Atomically sets whether `provider` currently grants this user Plus, then
 * recomputes profiles.plan as the OR of all providers' entitlements. One
 * provider reporting "no entitlement" can never erase another provider's
 * independently-tracked active grant — see apply_billing_reconciliation in
 * migrations/014_billing_webhook_events.sql.
 *
 * `eventTime`, when supplied, guards against an out-of-order/redelivered
 * webhook undoing a later event: if it is not newer than the last event
 * applied for this provider, the RPC reports current state ('stale')
 * without changing anything.
 */
export async function reconcileEntitlement(
  db: SupabaseClient,
  userId: string,
  provider: BillingProvider,
  active: boolean,
  eventTime?: Date,
): Promise<ReconciliationResult> {
  const { data, error } = await db.rpc('apply_billing_reconciliation', {
    p_user_id: userId,
    p_provider: provider,
    p_active: active,
    p_event_time: eventTime ? eventTime.toISOString() : null,
  })

  if (error) {
    throw new Error(`Billing reconciliation failed: ${error.message}`)
  }

  const result = data as ReconciliationResult | null
  if (!result || (result.status !== 'applied' && result.status !== 'stale')) {
    throw new Error('Billing reconciliation returned an unexpected result')
  }

  return result
}

/**
 * Records a webhook's (provider, eventId) so retried/duplicate deliveries
 * are detected. Returns true the first time an event id is seen, false on
 * every redelivery — callers should skip reprocessing on false.
 */
export async function claimWebhookEvent(
  db: SupabaseClient,
  provider: BillingProvider,
  eventId: string,
): Promise<boolean> {
  const { error } = await db.from('billing_webhook_events').insert({ provider, event_id: eventId })
  if (!error) return true
  if (error.code === '23505') return false
  throw new Error(`Failed to record webhook event: ${error.message}`)
}
