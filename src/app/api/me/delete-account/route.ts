import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/db/auth'
import { createServiceClient } from '@/lib/db/client'
import { getStripe } from '@/lib/stripe'
import type Stripe from 'stripe'

// Subscriptions in these statuses are already resolved and billing has
// stopped — nothing to cancel. Every other status (active, trialing,
// past_due, incomplete, unpaid, paused) still bills the customer and must
// be cancelled so deleting the account doesn't leave it being charged.
const TERMINAL_STATUSES = new Set<Stripe.Subscription.Status>(['canceled', 'incomplete_expired'])

// Deletes the user's ScrapLab account and all associated data. Every
// user-owned table (child_profiles, saved_projects, build_history,
// household_inventory) references profiles(id) on delete cascade, and
// profiles(id) references auth.users(id) on delete cascade — so deleting
// the auth user is sufficient to clean up everything.
export async function DELETE(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()

  // Best-effort: cancel any active Stripe subscription first, so deleting
  // the account doesn't leave the user being billed with no way to manage
  // it. A Stripe hiccup must never block the deletion itself — the user
  // explicitly asked for their account to be removed.
  const { data: profile } = await db
    .from('profiles')
    .select('stripe_customer_id')
    .eq('id', user.id)
    .single()

  if (profile?.stripe_customer_id) {
    try {
      const stripe = getStripe()
      let startingAfter: string | undefined
      const nonterminal: Stripe.Subscription[] = []

      do {
        const page = await stripe.subscriptions.list({
          customer: profile.stripe_customer_id,
          status: 'all',
          limit: 100,
          ...(startingAfter ? { starting_after: startingAfter } : {}),
        })
        nonterminal.push(...page.data.filter((s) => !TERMINAL_STATUSES.has(s.status)))
        startingAfter = page.has_more ? page.data[page.data.length - 1]?.id : undefined
      } while (startingAfter)

      await Promise.all(nonterminal.map((s) => stripe.subscriptions.cancel(s.id)))
    } catch (err) {
      console.error('delete-account: failed to cancel Stripe subscription', err)
    }
  }

  // Note: an Apple/RevenueCat subscription can't be cancelled from here —
  // Apple owns that billing relationship. The client is responsible for
  // telling iOS users to cancel it themselves via their Apple ID settings.
  const { error: deleteError } = await db.auth.admin.deleteUser(user.id)
  if (deleteError) {
    console.error('delete-account: failed to delete user', deleteError)
    return NextResponse.json({ error: 'Could not delete account. Please try again.' }, { status: 500 })
  }

  return new NextResponse(null, { status: 204 })
}
