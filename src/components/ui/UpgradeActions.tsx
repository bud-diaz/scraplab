'use client'
import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { useRouter } from 'next/navigation'
import { Button } from './Button'
import { Check, Sparkles } from 'lucide-react'

export function UpgradeActions() {
  const { user, session } = useAuth()
  const router = useRouter()
  const [plan, setPlan] = useState<'free' | 'plus' | null>(null)
  const [checkoutLoading, setCheckoutLoading] = useState(false)

  useEffect(() => {
    if (!user || !session) return
    fetch('/api/me/access', {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then(r => r.json())
      .then(data => setPlan(data.plan ?? 'free'))
      .catch(() => setPlan('free'))
  }, [user, session])

  const handleCheckout = async () => {
    if (!user || !session) {
      router.push('/auth')
      return
    }
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
        console.error('No checkout URL returned:', data)
        setCheckoutLoading(false)
      }
    } catch {
      setCheckoutLoading(false)
    }
  }

  if (plan === 'plus') {
    return (
      <div className="space-y-3">
        <div className="flex items-center justify-center gap-2 bg-orange-50 border border-orange-200 rounded-2xl py-3.5 px-4">
          <Sparkles size={16} className="text-orange-500" />
          <span className="text-sm font-heading font-semibold text-orange-600">
            You&apos;re on ScrapLab Plus
          </span>
          <Check size={14} className="text-orange-500" />
        </div>
        <Button
          variant="secondary"
          size="lg"
          className="w-full"
          onClick={() => router.push('/subscription')}
        >
          Manage subscription
        </Button>
        <p className="text-center text-xs text-walnut-500 font-body">
          Cancel or update payment from the billing portal.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <Button
        variant="primary"
        size="lg"
        className="w-full bg-orange-500 hover:bg-orange-600"
        onClick={handleCheckout}
        disabled={checkoutLoading}
      >
        {checkoutLoading ? 'Redirecting to checkout…' : 'Upgrade to ScrapLab Plus — $4.99/mo'}
      </Button>
      <p className="text-center text-xs text-walnut-500 font-body">Cancel anytime. No pressure.</p>
    </div>
  )
}
