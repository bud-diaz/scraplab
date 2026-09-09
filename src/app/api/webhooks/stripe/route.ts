import { NextRequest, NextResponse } from 'next/server'
import { getStripe } from '@/lib/stripe'
import { createServiceClient } from '@/lib/db/client'
import { claimWebhookEvent, reconcileEntitlement } from '@/lib/billing/entitlements'
import type Stripe from 'stripe'

// Subscription statuses that currently grant access. 'past_due' is kept
// active to give payment retries a grace period instead of cutting access
// on the first failed charge; Stripe will eventually transition it to
// 'canceled'/'unpaid' if retries keep failing, which does revoke access.
const ACTIVE_STATUSES = new Set<Stripe.Subscription.Status>(['active', 'trialing', 'past_due'])

async function reconcileForCustomer(
  db: ReturnType<typeof createServiceClient>,
  customerId: string,
  active: boolean,
  eventTime: Date,
) {
  const { data: profile } = await db
    .from('profiles')
    .select('id')
    .eq('stripe_customer_id', customerId)
    .maybeSingle()

  if (!profile) {
    console.warn('Stripe webhook: no profile for customer', customerId)
    return
  }

  await reconcileEntitlement(db, profile.id, 'stripe', active, eventTime)
}

export async function POST(request: NextRequest) {
  const body = await request.text()
  const sig = request.headers.get('stripe-signature')

  if (!sig) {
    return NextResponse.json({ error: 'Missing stripe-signature header' }, { status: 400 })
  }

  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET
  if (!webhookSecret) {
    return NextResponse.json({ error: 'Webhook secret not configured' }, { status: 503 })
  }

  let event: Stripe.Event
  try {
    event = getStripe().webhooks.constructEvent(body, sig, webhookSecret)
  } catch {
    return NextResponse.json({ error: 'Invalid webhook signature' }, { status: 400 })
  }

  const db = createServiceClient()

  const isNew = await claimWebhookEvent(db, 'stripe', event.id)
  if (!isNew) {
    return NextResponse.json({ received: true, duplicate: true })
  }

  const eventTime = new Date(event.created * 1000)

  try {
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session
      const userId = session.client_reference_id ?? session.metadata?.user_id ?? null
      const customerId = typeof session.customer === 'string' ? session.customer : null

      if (userId && customerId) {
        await db.from('profiles').update({ stripe_customer_id: customerId }).eq('id', userId)
        await reconcileEntitlement(db, userId, 'stripe', true, eventTime)
      }
    }

    if (event.type === 'customer.subscription.updated' || event.type === 'customer.subscription.deleted') {
      const subscription = event.data.object as Stripe.Subscription
      const customerId = typeof subscription.customer === 'string' ? subscription.customer : null
      const active = event.type === 'customer.subscription.deleted' ? false : ACTIVE_STATUSES.has(subscription.status)

      if (customerId) {
        await reconcileForCustomer(db, customerId, active, eventTime)
      }
    }
  } catch (err) {
    console.error('Stripe webhook: reconciliation failed', err)
    return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
  }

  return NextResponse.json({ received: true })
}
