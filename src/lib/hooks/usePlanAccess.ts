"use client"
import { useState, useEffect } from 'react'
import { useAuth } from '@/lib/auth-context'

export interface PlanAccess {
  plan: 'free' | 'plus'
  limits: { dailyRecommendations: number | null; savedProjects: number | null; childProfiles: number | null }
  usage: { recommendationsToday: number }
}

export function usePlanAccess(): PlanAccess | null {
  const { session } = useAuth()
  const [access, setAccess] = useState<PlanAccess | null>(null)

  useEffect(() => {
    if (!session) return
    fetch('/api/me/access', {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then(r => r.ok ? r.json() : null)
      .then(data => { if (data) setAccess(data) })
      .catch(() => {})
  }, [session])

  // Return null if not authenticated (without calling setAccess(null) synchronously)
  return session ? access : null
}
