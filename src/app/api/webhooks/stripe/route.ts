import { NextRequest, NextResponse } from 'next/server'
import { getStripe } from '@/lib/stripe'
import { createServiceClient } from '@/lib/db/client'
import type Stripe from 'stripe'

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

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session
    const userId = session.client_reference_id ?? session.metadata?.user_id ?? null
    const customerId = typeof session.customer === 'string' ? session.customer : null

    if (userId && customerId) {
      const { error: updateError } = await db
        .from('profiles')
        .update({ plan: 'plus', plan_source: 'stripe', stripe_customer_id: customerId })
        .eq('id', userId)
      if (updateError) {
        console.error('Stripe webhook: failed to upgrade plan', updateError)
        return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
      }
    }
  }

  if (event.type === 'customer.subscription.deleted') {
    const subscription = event.data.object as Stripe.Subscription
    const customerId = typeof subscription.customer === 'string' ? subscription.customer : null

    if (customerId) {
      const { error: updateError } = await db
        .from('profiles')
        .update({ plan: 'free' })
        .eq('stripe_customer_id', customerId)
        .eq('plan_source', 'stripe')
      if (updateError) {
        console.error('Stripe webhook: failed to downgrade plan', updateError)
        return NextResponse.json({ error: 'DB update failed' }, { status: 500 })
      }
    }
  }

  return NextResponse.json({ received: true })
}
