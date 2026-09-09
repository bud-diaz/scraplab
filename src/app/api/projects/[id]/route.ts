import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient, getUserFromRequest } from '@/lib/db/client'
import { resolveProject } from '@/lib/projects/resolve'
import { getUserPlan, redactPremiumProject } from '@/lib/access'

interface ProjectRow {
  id: string
  premium_only: boolean
  project_materials: Array<{ material_id: string }>
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  const db = createServiceClient()

  let project: ProjectRow | null
  try {
    project = await resolveProject<ProjectRow>(db, id, '*, project_materials(*, material:materials(*))')
  } catch {
    return NextResponse.json({ error: 'Project not found' }, { status: 404 })
  }

  if (!project) {
    return NextResponse.json({ error: 'Project not found' }, { status: 404 })
  }

  const user = await getUserFromRequest(request)
  const plan = user ? await getUserPlan(db, user.id) : 'free'
  project = redactPremiumProject(plan, project)

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
