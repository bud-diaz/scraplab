import type { SupabaseClient } from '@supabase/supabase-js'
import { createHash } from 'node:crypto'
import type { NextRequest } from 'next/server'

export interface ReservationResult {
  allowed: boolean
  remaining: number
  usedToday: number
  idempotentReplay?: boolean
}

export function getUserIdentity(userId: string): string {
  return `user:${userId}`
}

/** Guests are identified by a hashed IP — never stored/logged raw. */
export function getGuestIdentity(request: NextRequest): string {
  const ip =
    request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    request.headers.get('x-real-ip') ||
    'unknown'
  const hash = createHash('sha256').update(ip).digest('hex').slice(0, 32)
  return `guest:${hash}`
}

/**
 * Atomically checks and, if allowed, consumes one unit of today's
 * recommendation quota for `identity`. Pass `requestId` to make a retried
 * call idempotent instead of double-counting.
 */
export async function reserveRecommendationUsage(
  db: SupabaseClient,
  identity: string,
  dailyLimit: number,
  requestId?: string
): Promise<ReservationResult> {
  const { data, error } = await db.rpc('reserve_recommendation_usage', {
    p_identity: identity,
    p_daily_limit: dailyLimit,
    p_request_id: requestId ?? null,
  })
  if (error || !data) {
    throw new Error(error?.message ?? 'Could not check recommendation usage')
  }
  return data as ReservationResult
}

/** Read-only count for display (e.g. /api/me/access) — does not reserve. */
export async function getRecommendationUsageToday(db: SupabaseClient, identity: string): Promise<number> {
  const dayStart = new Date()
  dayStart.setUTCHours(0, 0, 0, 0)
  const { count } = await db
    .from('recommendation_usage')
    .select('*', { count: 'exact', head: true })
    .eq('identity', identity)
    .gte('created_at', dayStart.toISOString())
  return count ?? 0
}
