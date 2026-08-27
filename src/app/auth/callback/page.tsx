'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth-context'

export default function AuthCallbackPage() {
  const { user, session, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (loading || !user) return

    // Supabase auth-context picks up the #access_token from the URL hash
    // automatically via onAuthStateChange. Once that resolves, decide
    // whether this is a first-run user (no child profiles yet) who needs
    // the onboarding flow, or a returning user who goes straight home.
    let cancelled = false

    fetch('/api/child-profiles', {
      headers: { Authorization: `Bearer ${session?.access_token}` },
    })
      .then(res => (res.ok ? res.json() : { childProfiles: [] }))
      .then(data => {
        if (cancelled) return
        const hasProfiles = Array.isArray(data.childProfiles) && data.childProfiles.length > 0
        router.replace(hasProfiles ? '/' : '/onboarding')
      })
      .catch(() => {
        if (!cancelled) router.replace('/')
      })

    return () => {
      cancelled = true
    }
  }, [user, session, loading, router])

  return (
    <div className="min-h-screen bg-cream-50 flex items-center justify-center">
      <p className="text-sm text-walnut-600 font-body">Confirming your account…</p>
    </div>
  )
}
