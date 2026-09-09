import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { generateRecommendations } from '@/lib/recommendations'
import { getUserPlan, isWithinLimit, PLAN_LIMITS } from '@/lib/access'
import { generateAiSuggestions } from '@/lib/ai/suggestions'
import { uuidSchema } from '@/lib/validation/identifiers'

const bodySchema = z.object({
  materialIds: z.array(uuidSchema).min(1).max(50),
  childAge: z.number().int().min(0).max(18),
  preferences: z
    .object({
      maxTimeMinutes: z.number().int().min(1).optional(),
      cleanupLevel: z.enum(['low', 'medium', 'high']).optional(),
      supervisionLevel: z
        .enum(['independent', 'check_in', 'adult_assist', 'full_supervision'])
        .optional(),
    })
    .optional(),
})

export async function POST(request: NextRequest) {
  const { user, error: authError } = await requireAuth(request)
  if (authError) return authError

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

  const db = createServiceClient()
  const plan = await getUserPlan(db, user.id)

  // Check daily recommendation limit for free users
  if (plan === 'free') {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const { count } = await db
      .from('build_history')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .gte('started_at', today.toISOString())

    const used = count ?? 0
    if (!isWithinLimit(plan, 'dailyRecommendations', used)) {
      return NextResponse.json(
        {
          error: 'Daily recommendation limit reached',
          limit: PLAN_LIMITS.free.dailyRecommendations,
          upgradeRequired: true,
        },
        { status: 429 }
      )
    }
  }

  // Load all projects with their materials, plus the user's selected materials by name
  const [projectResult, materialsResult] = await Promise.all([
    db.from('projects').select('*, project_materials(material_id, required, quantity_note)'),
    db.from('materials').select('id, name').in('id', parsed.data.materialIds),
  ])

  if (projectResult.error) {
    return NextResponse.json({ error: projectResult.error.message }, { status: 500 })
  }

  // Load all substitutions
  const { data: subs } = await db
    .from('material_substitutions')
    .select('source_material_id, replacement_material_id, substitution_notes')

  const projectsWithMaterials = (projectResult.data ?? []).map((p) => ({
    project: p,
    materials: p.project_materials,
  }))

  const recommendations = generateRecommendations(
    parsed.data,
    projectsWithMaterials,
    subs ?? []
  )

  // AI fallback: fire when the DB engine returns fewer than 3 results
  let aiSuggestions: Awaited<ReturnType<typeof generateAiSuggestions>> = []
  if (recommendations.length < 3) {
    const materialNames = (materialsResult.data ?? []).map((m) => m.name)
    aiSuggestions = await generateAiSuggestions(
      materialNames,
      parsed.data.childAge,
      3 - recommendations.length
    )
  }

  return NextResponse.json({ recommendations, aiSuggestions })
}
