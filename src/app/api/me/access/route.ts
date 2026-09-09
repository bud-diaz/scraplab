import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, getPlanLimits } from '@/lib/access'
import { getRecommendationUsageToday, getUserIdentity } from '@/lib/access/recommendation-usage'

export async function GET(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const plan = await getUserPlan(db, user.id)
  const limits = getPlanLimits(plan)

  const recommendationsToday = await getRecommendationUsageToday(db, getUserIdentity(user.id))

  return NextResponse.json({
    plan,
    limits: {
      dailyRecommendations: limits.dailyRecommendations === Infinity ? null : limits.dailyRecommendations,
      photoScan: limits.photoScan,
      childProfiles: limits.childProfiles === Infinity ? null : limits.childProfiles,
      savedProjects: limits.savedProjects === Infinity ? null : limits.savedProjects,
    },
    usage: {
      recommendationsToday,
    },
  })
}
