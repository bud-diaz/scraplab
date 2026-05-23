import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, getPlanLimits } from '@/lib/access'

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const plan = await getUserPlan(db, user.id)
  const limits = getPlanLimits(plan)

  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const { count: recommendationsToday } = await db
    .from('build_history')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .gte('started_at', today.toISOString())

  return NextResponse.json({
    plan,
    limits: {
      dailyRecommendations: limits.dailyRecommendations === Infinity ? null : limits.dailyRecommendations,
      photoScan: limits.photoScan,
      childProfiles: limits.childProfiles === Infinity ? null : limits.childProfiles,
      savedProjects: limits.savedProjects === Infinity ? null : limits.savedProjects,
    },
    usage: {
      recommendationsToday: recommendationsToday ?? 0,
    },
  })
}
