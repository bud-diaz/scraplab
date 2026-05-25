import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { generateAiSuggestions } from '@/lib/ai/suggestions'
import { z } from 'zod'
import type { Activity } from '@/types'

const bodySchema = z.object({
  materialIds: z.array(z.string()).min(1).max(50),
  childAge: z.number().int().min(0).max(18),
})

export type MatchLabel = 'Perfect Match' | 'Good Match' | 'Partial Match'

export interface ActivityMatch {
  activity: Activity
  matchedCount: number
  totalRequired: number
  matchScore: number
  matchLabel: MatchLabel
}

function ageToRangeBucket(age: number): string {
  if (age <= 5) return '3-5'
  if (age <= 8) return '6-8'
  if (age <= 12) return '9-12'
  return '13+'
}

function matchLabel(score: number): MatchLabel {
  if (score >= 1) return 'Perfect Match'
  if (score >= 0.5) return 'Good Match'
  return 'Partial Match'
}

export async function POST(request: NextRequest) {
  let body: unknown
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 })
  }

  const parsed = bodySchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }

  const { materialIds, childAge } = parsed.data
  const db = createServiceClient()

  // 1. Resolve material IDs → flat set of lowercase strings (name + all aliases)
  const { data: materials, error: matErr } = await db
    .from('materials')
    .select('name, aliases')
    .in('id', materialIds)

  if (matErr) {
    return NextResponse.json({ error: matErr.message }, { status: 500 })
  }

  const resolvedStrings = Array.from(new Set(
    (materials ?? []).flatMap(m => [
      m.name.toLowerCase(),
      ...(m.aliases ?? []).map((a: string) => a.toLowerCase()),
    ])
  ))

  if (resolvedStrings.length === 0) {
    return NextResponse.json({ matches: [], aiSuggestions: [] })
  }

  // 2. Age bucket for filtering
  const ageBucket = ageToRangeBucket(childAge)

  // 3. Query activities with array overlap on materials_required + age filter
  // Supabase .overlaps() maps to the && Postgres operator
  const { data: activities, error: actErr } = await db
    .from('activities')
    .select('*')
    .overlaps('materials_required', resolvedStrings)
    .or(`age_ranges.cs.{"${ageBucket}"},age_ranges.cs.{"family"}`)

  if (actErr) {
    return NextResponse.json({ error: actErr.message }, { status: 500 })
  }

  // 4. Score each activity by how many of its required materials the user has
  const matches: ActivityMatch[] = (activities ?? []).map((a: Activity) => {
    const required = (a.materials_required ?? []).map((s: string) => s.toLowerCase())
    const matched = required.filter((r: string) =>
      resolvedStrings.some(s => s === r || r.includes(s) || s.includes(r))
    )
    const matchedCount = matched.length
    const totalRequired = required.length || 1
    const score = matchedCount / totalRequired
    return {
      activity: a,
      matchedCount,
      totalRequired,
      matchScore: score,
      matchLabel: matchLabel(score),
    }
  })

  // Sort best match first
  matches.sort((a, b) => b.matchScore - a.matchScore)

  // 5. AI fallback when fewer than 3 DB matches
  let aiSuggestions = []
  if (matches.length < 3) {
    const materialNames = (materials ?? []).map(m => m.name)
    const needed = 3 - matches.length
    aiSuggestions = await generateAiSuggestions(materialNames, childAge, needed)
  }

  return NextResponse.json({ matches, aiSuggestions })
}
