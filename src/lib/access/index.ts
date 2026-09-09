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

/**
 * Redacts the paid "how to actually do it" content for a premium project
 * when the caller isn't Plus, while keeping everything a free/guest user
 * needs to decide whether to upgrade (title, materials, safety notes,
 * metadata) visible. Never call this with data that skipped the DB read
 * entirely — it only hides step-by-step instructions, not the row.
 */
export function redactPremiumProject<T extends { premium_only: boolean; instructions?: unknown }>(
  plan: Plan,
  project: T
): T & { previewOnly?: boolean } {
  if (!project.premium_only || plan === 'plus') return project
  return { ...project, instructions: [], previewOnly: true }
}

/**
 * Same idea for activities: premium gates the descriptive/expansion
 * content, never the materials list or safety notes — a preview must
 * never hide a safety warning to create upsell pressure.
 */
export function redactPremiumActivity<
  T extends { premium: boolean; description?: unknown; expansion_prompts?: unknown; learning_angle?: unknown }
>(plan: Plan, activity: T): T & { previewOnly?: boolean } {
  if (!activity.premium || plan === 'plus') return activity
  return { ...activity, description: null, expansion_prompts: [], learning_angle: null, previewOnly: true }
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
