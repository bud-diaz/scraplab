'use client'
import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { createClient } from '@supabase/supabase-js'
import type { SupabaseClient, Session, User } from '@supabase/supabase-js'
import { configureRevenueCat } from './native/purchases'

// Lazy singleton — avoids module-level createClient() running during
// Next.js build prerendering before NEXT_PUBLIC_* vars are injected.
let _client: SupabaseClient | null = null
function getClient(): SupabaseClient {
  if (!_client) {
    _client = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )
  }
  return _client
}

interface AuthContextValue {
  user: User | null
  session: Session | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>
  signUp: (email: string, password: string) => Promise<{ error: Error | null; needsConfirmation: boolean }>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue>({
  user: null,
  session: null,
  loading: true,
  signIn: async () => ({ error: null }),
  signUp: async () => ({ error: null, needsConfirmation: false }),
  signOut: async () => {},
})

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const sb = getClient()

    sb.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      setLoading(false)
      if (session?.user) configureRevenueCat(session.user.id)
    })

    const { data: { subscription } } = sb.auth.onAuthStateChange((_, session) => {
      setSession(session)
      setUser(session?.user ?? null)
      if (session?.user) configureRevenueCat(session.user.id)
    })

    return () => subscription.unsubscribe()
  }, [])

  const signIn = useCallback(async (email: string, password: string) => {
    const { error } = await getClient().auth.signInWithPassword({ email, password })
    return { error }
  }, [])

  const signUp = useCallback(async (email: string, password: string) => {
    const redirectTo = `${window.location.origin}/auth/callback`
    const { data, error } = await getClient().auth.signUp({
      email,
      password,
      options: { emailRedirectTo: redirectTo },
    })
    return { error, needsConfirmation: !error && !data.session }
  }, [])

  const signOut = useCallback(async () => {
    await getClient().auth.signOut()
  }, [])

  return (
    <AuthContext.Provider value={{ user, session, loading, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
