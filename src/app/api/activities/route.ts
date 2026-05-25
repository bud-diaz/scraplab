import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { z } from 'zod'

const querySchema = z.object({
  category: z.string().optional(),
  difficulty: z.enum(['easy', 'medium', 'hard', 'adaptive']).optional(),
  age_range: z.string().optional(),
  time_max: z.coerce.number().int().min(1).optional(),
  energy_level: z.string().optional(),
  scrap_tag: z.string().optional(),
  search: z.string().optional(),
  premium: z.enum(['true', 'false']).optional(),
  featured: z.enum(['true', 'false']).optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
})

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const parsed = querySchema.safeParse(Object.fromEntries(searchParams))
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }

  const { category, difficulty, age_range, time_max, energy_level, scrap_tag, search, premium, featured, limit = 50, offset = 0 } = parsed.data
  const db = createServiceClient()

  let query = db
    .from('activities')
    .select('*', { count: 'exact' })
    .order('title')
    .range(offset, offset + limit - 1)

  if (category) query = query.eq('category', category)
  if (difficulty) query = query.eq('difficulty', difficulty)
  if (energy_level) query = query.eq('energy_level', energy_level)
  if (time_max !== undefined) query = query.lte('time_minutes', time_max)
  if (premium !== undefined) query = query.eq('premium', premium === 'true')
  if (featured !== undefined) query = query.eq('featured', featured === 'true')
  if (age_range) query = query.contains('age_ranges', [age_range])
  if (scrap_tag) query = query.contains('scrap_tags', [scrap_tag])
  if (search) query = query.or(`title.ilike.%${search}%,one_liner.ilike.%${search}%,description.ilike.%${search}%`)

  const { data, error, count } = await query
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ activities: data ?? [], total: count ?? 0 })
}
