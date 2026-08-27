'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { AppShell } from '@/components/layout/AppShell'
import { Button } from '@/components/ui/Button'
import { useAuth } from '@/lib/auth-context'
import { ArrowLeft, Sparkles, Check, ExternalLink, Zap } from 'lucide-react'
import Link from 'next/link'

const plusFeatures = [
  'Unlimited builds per day',
  'Photo material scanner',
  'Household staples saved list',
  'Up to 10 child profiles',
  'Challenge mode',
  'Mystery builds',
  'Unlimited saved projects',
]

export default function SubscriptionPage() {
  const { user, session } = useAuth()
  const router = useRouter()
  const [plan, setPlan] = useState<'free' | 'plus' | null>(null)
  const [pageLoading, setPageLoading] = useState(true)
  const [portalLoading, setPortalLoading] = useState(false)
  const [checkoutLoading, setCheckoutLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!user || !session) {
      router.replace('/auth')
      return
    }
    fetch('/api/me/access', {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then(r => r.json())
      .then(data => setPlan(data.plan ?? 'free'))
      .catch(() => setPlan('free'))
      .finally(() => setPageLoading(false))
  }, [user, session, router])

  const handlePortal = async () => {
    if (!session) return
    setError(null)
    setPortalLoading(true)
    try {
      const res = await fetch('/api/billing/portal', {
        method: 'POST',
        headers: { Authorization: `Bearer ${session.access_token}` },
      })
      const data = await res.json()
      if (data.url) {
        window.location.href = data.url
      } else {
        setError(data.error ?? 'Could not open billing portal. Please contact support.')
        setPortalLoading(false)
      }
    } catch {
      setError('Network error. Please try again.')
      setPortalLoading(false)
    }
  }

  const handleCheckout = async () => {
    if (!session) return
    setError(null)
    setCheckoutLoading(true)
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { Authorization: `Bearer ${session.access_token}` },
      })
      const data = await res.json()
      if (data.url) {
        window.location.href = data.url
      } else {
        setError(data.error ?? 'Could not start checkout. Please try again.')
        setCheckoutLoading(false)
      }
    } catch {
      setError('Network error. Please try again.')
      setCheckoutLoading(false)
    }
  }

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-2 flex items-center gap-3">
          <Link href="/profile" className="text-walnut-500 hover:text-walnut-700 transition-colors">
            <ArrowLeft size={20} />
          </Link>
          <h1 className="font-heading font-bold text-xl text-charcoal-900">Subscription</h1>
        </div>

        {pageLoading ? (
          <div className="px-4 pt-8 space-y-3">
            <div className="h-16 bg-cream-100 rounded-2xl animate-pulse" />
            <div className="h-48 bg-cream-100 rounded-3xl animate-pulse" />
          </div>
        ) : plan === 'plus' ? (
          <div className="px-4 pt-6 space-y-4 pb-8">
            <div className="flex items-center gap-3 bg-orange-50 border border-orange-200 rounded-2xl py-4 px-5">
              <Sparkles size={18} className="text-orange-500 shrink-0" />
              <div>
                <p className="font-heading font-bold text-charcoal-900 text-sm">ScrapLab Plus</p>
                <p className="text-xs text-walnut-600 font-body">Active subscription · $4.99/mo</p>
              </div>
              <Check size={16} className="text-orange-500 ml-auto shrink-0" />
            </div>

            <div className="bg-white rounded-3xl shadow-card p-5">
              <p className="font-heading font-semibold text-sm text-charcoal-900 mb-3">Your Plus features</p>
              <div className="space-y-2.5">
                {plusFeatures.map(f => (
                  <div key={f} className="flex items-center gap-2">
                    <Check size={13} className="text-orange-500 shrink-0" />
                    <span className="text-xs font-body text-walnut-700">{f}</span>
                  </div>
                ))}
              </div>
            </div>

            {error && (
              <div className="bg-coral/10 border border-coral/30 rounded-2xl px-4 py-3">
                <p className="text-sm text-coral-text font-body">{error}</p>
              </div>
            )}

            <div className="space-y-2">
              <Button
                variant="secondary"
                size="lg"
                className="w-full gap-2"
                onClick={handlePortal}
                disabled={portalLoading}
              >
                <ExternalLink size={15} />
                {portalLoading ? 'Opening portal…' : 'Manage billing & cancel'}
              </Button>
              <p className="text-center text-xs text-walnut-500 font-body">
                Update your payment method or cancel anytime from the Stripe billing portal.
              </p>
            </div>
          </div>
        ) : (
          <div className="px-4 pt-6 space-y-4 pb-8">
            <div className="flex items-center gap-3 bg-cream-100 rounded-2xl py-4 px-5">
              <Zap size={18} className="text-walnut-500 shrink-0" />
              <div>
                <p className="font-heading font-bold text-charcoal-900 text-sm">Free plan</p>
                <p className="text-xs text-walnut-600 font-body">3 builds/day · 10 saved projects</p>
              </div>
            </div>

            <div className="bg-scraplab-blue rounded-3xl p-6 text-white relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full -translate-y-10 translate-x-10" />
              <div className="relative">
                <div className="flex items-center gap-2 mb-1">
                  <Sparkles size={15} className="text-sunshine" />
                  <span className="font-heading font-bold text-sm text-sunshine uppercase tracking-wide">ScrapLab Plus</span>
                </div>
                <div className="flex items-baseline gap-1 mb-4">
                  <span className="font-heading font-bold text-3xl">$4.99</span>
                  <span className="text-white/80 text-sm">/mo</span>
                </div>
                <div className="space-y-2 mb-5">
                  {plusFeatures.map(f => (
                    <div key={f} className="flex items-center gap-2">
                      <Check size={12} className="text-white shrink-0" />
                      <span className="text-xs font-body text-white/90">{f}</span>
                    </div>
                  ))}
                </div>

                {error && (
                  <div className="bg-coral/20 border border-white/30 rounded-xl px-3 py-2 mb-3">
                    <p className="text-xs text-white font-body">{error}</p>
                  </div>
                )}

                <Button
                  variant="primary"
                  size="lg"
                  className="w-full bg-white text-orange-600 hover:bg-white/90"
                  onClick={handleCheckout}
                  disabled={checkoutLoading}
                >
                  {checkoutLoading ? 'Redirecting to checkout…' : 'Upgrade to Plus — $4.99/mo'}
                </Button>
                <p className="text-center text-white/70 text-xs font-body mt-2">Cancel anytime. No pressure.</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  )
}
