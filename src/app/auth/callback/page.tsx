'use client'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth-context'

export default function AuthCallbackPage() {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading) {
      // Supabase auth-context picks up the #access_token from the URL hash
      // automatically via onAuthStateChange. Once that resolves, redirect home.
      router.replace('/')
    }
  }, [user, loading, router])

  return (
    <div className="min-h-screen bg-cream-50 flex items-center justify-center">
      <p className="text-sm text-walnut-600 font-body">Confirming your account…</p>
    </div>
  )
}
