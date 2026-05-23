import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  const db = createServiceClient()

  const { data: project, error } = await db
    .from('projects')
    .select('*, project_materials(*, material:materials(*))')
    .eq('id', id)
    .single()

  if (error || !project) {
    return NextResponse.json({ error: 'Project not found' }, { status: 404 })
  }

  // Fetch substitutions for all materials in this project
  const materialIds = project.project_materials.map(
    (pm: { material_id: string }) => pm.material_id
  )

  const { data: substitutions } = await db
    .from('material_substitutions')
    .select('*, source:materials!source_material_id(id,name), replacement:materials!replacement_material_id(id,name)')
    .in('source_material_id', materialIds)

  return NextResponse.json({ project, substitutions: substitutions ?? [] })
}
