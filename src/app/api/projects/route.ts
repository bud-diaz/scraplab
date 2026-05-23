import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { z } from 'zod'

const querySchema = z.object({
  age: z.coerce.number().int().min(0).max(18).optional(),
  materials: z.string().optional(), // comma-separated material IDs
  time: z.coerce.number().int().min(1).optional(),
  cleanup_level: z.enum(['low', 'medium', 'high']).optional(),
  supervision_level: z
    .enum(['independent', 'check_in', 'adult_assist', 'full_supervision'])
    .optional(),
  difficulty: z.enum(['easy', 'medium', 'advanced']).optional(),
})

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const parsed = querySchema.safeParse(Object.fromEntries(searchParams))
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }

  const filters = parsed.data
  const db = createServiceClient()

  let query = db
    .from('projects')
    .select('*, project_materials(*, material:materials(*))')
    .order('title')

  if (filters.age !== undefined) {
    query = query.lte('age_min', filters.age).gte('age_max', filters.age)
  }
  if (filters.time !== undefined) {
    query = query.lte('time_minutes', filters.time)
  }
  if (filters.cleanup_level) {
    query = query.eq('cleanup_level', filters.cleanup_level)
  }
  if (filters.supervision_level) {
    query = query.eq('supervision_level', filters.supervision_level)
  }
  if (filters.difficulty) {
    query = query.eq('difficulty', filters.difficulty)
  }

  const { data, error } = await query
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  let projects = data ?? []

  // Material filter: project must require at least one of the given materials
  if (filters.materials) {
    const materialIds = filters.materials.split(',').filter(Boolean)
    if (materialIds.length > 0) {
      projects = projects.filter((p) =>
        p.project_materials.some((pm: { material_id: string }) =>
          materialIds.includes(pm.material_id)
        )
      )
    }
  }

  return NextResponse.json({ projects })
}
