import type { Plan, AccessLimits } from '@/types'

export const PLAN_LIMITS: Record<Plan, AccessLimits> = {
  free: {
    dailyRecommendations: 3,
    photoScan: false,
    childProfiles: 1,
    savedProjects: 10,
  },
  plus: {
    dailyRecommendations: Infinity,
    photoScan: true,
    childProfiles: 10,
    savedProjects: Infinity,
  },
}

export function getPlanLimits(plan: Plan): AccessLimits {
  return PLAN_LIMITS[plan]
}

export function isWithinLimit(
  plan: Plan,
  feature: keyof AccessLimits,
  currentCount: number
): boolean {
  const limit = PLAN_LIMITS[plan][feature]
  if (typeof limit === 'boolean') return limit
  return currentCount < limit
}

export function canUsePhotoScan(plan: Plan): boolean {
  return PLAN_LIMITS[plan].photoScan
}

export function isPremiumProject(plan: Plan, premiumOnly: boolean): boolean {
  if (!premiumOnly) return true
  return plan === 'plus'
}

export async function getUserPlan(
  supabase: ReturnType<typeof import('../db/client').createServiceClient>,
  userId: string
): Promise<Plan> {
  const { data } = await supabase
    .from('profiles')
    .select('plan')
    .eq('id', userId)
    .single()
  return (data?.plan as Plan) ?? 'free'
}
