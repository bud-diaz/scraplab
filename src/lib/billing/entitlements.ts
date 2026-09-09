import type { SupabaseClient } from '@supabase/supabase-js'

export type BillingProvider = 'stripe' | 'revenuecat'
export type Plan = 'free' | 'plus'

export interface ReconciliationResult {
  status: 'applied'
  plan: Plan
}

/**
 * Atomically sets whether `provider` currently grants this user Plus, then
 * recomputes profiles.plan as the OR of all providers' entitlements. One
 * provider reporting "no entitlement" can never erase another provider's
 * independently-tracked active grant — see apply_billing_reconciliation in
 * migrations/012_billing_reconciliation.sql.
 */
export async function reconcileEntitlement(
  db: SupabaseClient,
  userId: string,
  provider: BillingProvider,
  active: boolean,
): Promise<ReconciliationResult> {
  const { data, error } = await db.rpc('apply_billing_reconciliation', {
    p_user_id: userId,
    p_provider: provider,
    p_active: active,
  })

  if (error) {
    throw new Error(`Billing reconciliation failed: ${error.message}`)
  }

  const result = data as ReconciliationResult | null
  if (!result || result.status !== 'applied') {
    throw new Error('Billing reconciliation returned an unexpected result')
  }

  return result
}
