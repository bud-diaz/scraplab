import type { SupervisionLevel } from '@/types'

export const HARD_BLOCKED_KEYWORDS = [
  'fire', 'flame', 'burn', 'lighter', 'match',
  'knife', 'blade', 'razor', 'cut with knife',
  'toxic', 'bleach', 'chemical reaction', 'ammonia',
  'electrical', 'wire', 'outlet', 'battery acid',
  'hazardous', 'explosive',
]

// Minimum supervision required per age group
const MIN_SUPERVISION_BY_AGE: Record<string, SupervisionLevel> = {
  under4: 'full_supervision',
  age4to6: 'adult_assist',
  age7to10: 'check_in',
  age11plus: 'independent',
}

const SUPERVISION_ORDER: SupervisionLevel[] = [
  'full_supervision',
  'adult_assist',
  'check_in',
  'independent',
]

function getAgeGroup(age: number): keyof typeof MIN_SUPERVISION_BY_AGE {
  if (age < 4) return 'under4'
  if (age <= 6) return 'age4to6'
  if (age <= 10) return 'age7to10'
  return 'age11plus'
}

export function isSupervisionSufficientForAge(
  projectSupervision: SupervisionLevel,
  childAge: number
): boolean {
  const group = getAgeGroup(childAge)
  const minRequired = MIN_SUPERVISION_BY_AGE[group]
  return (
    SUPERVISION_ORDER.indexOf(projectSupervision) <=
    SUPERVISION_ORDER.indexOf(minRequired)
  )
}

export function isProjectAgeAppropriate(
  project: { age_min: number; age_max: number; supervision_level: SupervisionLevel },
  childAge: number
): boolean {
  if (childAge < project.age_min || childAge > project.age_max) return false
  return isSupervisionSufficientForAge(project.supervision_level, childAge)
}
