import type {
  Project,
  ProjectRecommendation,
  RecommendationInput,
  MatchType,
  SuggestedSubstitution,
} from '@/types'
import { isProjectAgeAppropriate } from '@/lib/safety'

interface ProjectMaterialRow {
  material_id: string
  required: boolean
  quantity_note: string | null
}

interface SubstitutionRow {
  source_material_id: string
  replacement_material_id: string
  substitution_notes: string | null
}

interface ProjectWithMaterialRows {
  project: Project
  materials: ProjectMaterialRow[]
}

export function generateRecommendations(
  input: RecommendationInput,
  projectsWithMaterials: ProjectWithMaterialRows[],
  substitutions: SubstitutionRow[]
): ProjectRecommendation[] {
  const { materialIds, childAge, preferences = {} } = input
  const available = new Set(materialIds)

  // Build substitution lookup: source_material_id → [substitution rows]
  const subMap = new Map<string, SubstitutionRow[]>()
  for (const sub of substitutions) {
    const list = subMap.get(sub.source_material_id) ?? []
    list.push(sub)
    subMap.set(sub.source_material_id, list)
  }

  const results: ProjectRecommendation[] = []

  for (const { project, materials } of projectsWithMaterials) {
    // Hard age + safety gate
    if (!isProjectAgeAppropriate(project, childAge)) continue

    // Hard preference filters
    if (
      preferences.maxTimeMinutes !== undefined &&
      project.time_minutes > preferences.maxTimeMinutes
    )
      continue

    const required = materials.filter((m) => m.required)
    const optional = materials.filter((m) => !m.required)

    const coveredRequired: string[] = []
    const missingRequired: string[] = []
    const suggestedSubstitutions: SuggestedSubstitution[] = []

    for (const rm of required) {
      if (available.has(rm.material_id)) {
        coveredRequired.push(rm.material_id)
      } else {
        const subs = subMap.get(rm.material_id) ?? []
        const usable = subs.find((s) => available.has(s.replacement_material_id))
        if (usable) {
          coveredRequired.push(rm.material_id)
          suggestedSubstitutions.push({
            missingMaterialId: rm.material_id,
            replacementMaterialId: usable.replacement_material_id,
            notes: usable.substitution_notes,
          })
        } else {
          missingRequired.push(rm.material_id)
        }
      }
    }

    // Skip if more than half of required materials are truly missing
    if (required.length > 0 && missingRequired.length > Math.floor(required.length / 2))
      continue

    const coveredOptional = optional.filter((m) => available.has(m.material_id))

    // Score components
    const requiredScore = required.length > 0 ? coveredRequired.length / required.length : 1.0
    const optionalBonus =
      optional.length > 0 ? (coveredOptional.length / optional.length) * 0.1 : 0
    let prefBonus = 0
    if (preferences.cleanupLevel === project.cleanup_level) prefBonus += 0.05
    if (preferences.supervisionLevel === project.supervision_level) prefBonus += 0.05

    const matchScore = Math.min(1.0, requiredScore + optionalBonus + prefBonus)

    let matchType: MatchType
    if (missingRequired.length === 0 && suggestedSubstitutions.length === 0) {
      matchType = 'exact'
    } else if (missingRequired.length === 0) {
      matchType = 'close'
    } else {
      matchType = missingRequired.length <= Math.floor(required.length / 2) ? 'close' : 'fallback'
    }

    let reason: string
    if (matchType === 'exact') {
      reason = 'You have all the materials needed.'
    } else if (suggestedSubstitutions.length > 0 && missingRequired.length === 0) {
      reason = `You can substitute ${suggestedSubstitutions.length} material${suggestedSubstitutions.length > 1 ? 's' : ''} with what you have.`
    } else if (missingRequired.length > 0) {
      reason = `Missing ${missingRequired.length} material${missingRequired.length > 1 ? 's' : ''}, but you have the main ones.`
    } else {
      reason = 'This project works well with your materials.'
    }

    const allUsed = [
      ...coveredRequired,
      ...coveredOptional.map((m) => m.material_id),
    ]

    results.push({
      projectId: project.id,
      title: project.title,
      matchType,
      matchScore: Math.round(matchScore * 100) / 100,
      missingRequiredMaterials: missingRequired,
      availableMaterialsUsed: [...new Set(allUsed)],
      suggestedSubstitutions,
      reason,
    })
  }

  // Sort: exact → close → fallback, then by score descending
  const typeOrder: Record<MatchType, number> = { exact: 0, close: 1, fallback: 2 }
  results.sort((a, b) => {
    const t = typeOrder[a.matchType] - typeOrder[b.matchType]
    return t !== 0 ? t : b.matchScore - a.matchScore
  })

  return results
}
