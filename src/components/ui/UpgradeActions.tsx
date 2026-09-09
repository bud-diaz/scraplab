'use client'
import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'
import { useRouter } from 'next/navigation'
import { Button } from './Button'
import { Check, Sparkles } from 'lucide-react'
import { isNativeIOS, getPlusPackage, purchasePlus, getManagementURL } from '@/lib/native/purchases'
import type { PurchasesPackage } from '@revenuecat/purchases-capacitor'
import { Haptics, ImpactStyle } from '@capacitor/haptics'

function isUserCancelled(err: unknown): boolean {
  return typeof err === 'object' && err !== null && 'userCancelled' in err && (err as { userCancelled?: boolean }).userCancelled === true
}

export function UpgradeActions() {
  const { user, session } = useAuth()
  const router = useRouter()
  const [plan, setPlan] = useState<'free' | 'plus' | null>(null)
  const [checkoutLoading, setCheckoutLoading] = useState(false)
  const [manageLoading, setManageLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const native = isNativeIOS()
  const [nativePackage, setNativePackage] = useState<PurchasesPackage | null>(null)

  useEffect(() => {
    if (!user || !session) return
    const refresh = () => {
      fetch('/api/me/access', {
        headers: { Authorization: `Bearer ${session.access_token}` },
      })
        .then(r => r.json())
        .then(data => setPlan(data.plan ?? 'free'))
        .catch(() => setPlan('free'))
    }
    refresh()
    window.addEventListener('scraplab:refresh-plan', refresh)
    return () => window.removeEventListener('scraplab:refresh-plan', refresh)
  }, [user, session])

  useEffect(() => {
    if (!native) return
    getPlusPackage().then(setNativePackage).catch(() => setNativePackage(null))
  }, [native])

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

  const handleNativePurchase = async () => {
    if (!user || !session) {
      router.push('/auth')
      return
    }
    if (!nativePackage) return
    setError(null)
    setCheckoutLoading(true)
    try {
      const granted = await purchasePlus(nativePackage)
      if (granted) {
        const res = await fetch('/api/me/sync-revenuecat', {
          method: 'POST',
          headers: { Authorization: `Bearer ${session.access_token}` },
        })
        if (res.ok) {
          const data = await res.json()
          setPlan(data.plan ?? 'free')
          if (data.plan === 'plus') {
            Haptics.impact({ style: ImpactStyle.Medium }).catch(() => {})
          } else {
            setError('Purchase completed, but verification is still pending. Pull to refresh in a moment.')
          }
        } else {
          setError('Purchase completed, but we could not verify it yet. Try "Manage subscription" or restart the app in a moment.')
        }
      } else {
        setError('Purchase did not complete. Please try again.')
      }
    } catch (err) {
      if (!isUserCancelled(err)) setError('Purchase failed. Please try again.')
    } finally {
      setCheckoutLoading(false)
    }
  }

  const handleManageNative = async () => {
    setManageLoading(true)
    try {
      const url = await getManagementURL()
      if (url) window.location.href = url
    } finally {
      setManageLoading(false)
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
          onClick={native ? handleManageNative : () => router.push('/subscription')}
          disabled={native && manageLoading}
        >
          {native ? (manageLoading ? 'Opening…' : 'Manage subscription') : 'Manage subscription'}
        </Button>
        <p className="text-center text-xs text-walnut-500 font-body">
          {native
            ? 'Cancel or update payment from your Apple ID subscription settings.'
            : 'Cancel or update payment from the billing portal.'}
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {error && (
        <p className="text-center text-xs text-coral-text font-body">{error}</p>
      )}
      <Button
        variant="primary"
        size="lg"
        className="w-full bg-orange-500 hover:bg-orange-600"
        onClick={native ? handleNativePurchase : handleCheckout}
        disabled={checkoutLoading || (native && !nativePackage)}
      >
        {checkoutLoading
          ? 'Redirecting to checkout…'
          : `Upgrade to ScrapLab Plus — ${native ? (nativePackage?.product.priceString ?? '…') : '$4.99/mo'}`}
      </Button>
      <p className="text-center text-xs text-walnut-500 font-body">Cancel anytime. No pressure.</p>
    </div>
  )
}
