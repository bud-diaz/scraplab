import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { z } from 'zod'

const querySchema = z.object({
  category: z.string().optional(),
})

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const parsed = querySchema.safeParse(Object.fromEntries(searchParams))
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }

  const db = createServiceClient()
  let query = db.from('materials').select('*').order('name')

  if (parsed.data.category) {
    query = query.eq('category', parsed.data.category)
  }

  const { data, error } = await query
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  // Group by category when no filter is applied
  if (!parsed.data.category) {
    const grouped = (data ?? []).reduce<Record<string, typeof data>>((acc, m) => {
      if (!acc[m.category]) acc[m.category] = []
      acc[m.category].push(m)
      return acc
    }, {})
    return NextResponse.json({ grouped, materials: data })
  }

  return NextResponse.json({ materials: data })
}
