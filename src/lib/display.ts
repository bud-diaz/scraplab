import type { MatchType, SupervisionLevel } from '@/types'

export interface DisplayProject {
  id: string
  slug: string
  title: string
  description: string
  timeEstimate: string
  ageRange: string
  cleanupLevel: string
  supervisionLevel: string
  supervisionLevelRaw: SupervisionLevel
  difficulty: string
  emoji: string
  bgColor: string
  matchLabel?: 'Great Match' | 'Close Match' | 'Partial Match'
}

const SLUG_DISPLAY: Record<string, { emoji: string; bgColor: string }> = {
  'cardboard-rocket-ship':     { emoji: '🚀', bgColor: 'bg-builder-500' },
  'bottle-cap-robot':          { emoji: '🤖', bgColor: 'bg-walnut-700' },
  'egg-carton-creature':       { emoji: '🐛', bgColor: 'bg-kraft-500' },
  'cup-and-string-phone':      { emoji: '📞', bgColor: 'bg-orange-500' },
  'cereal-box-puppet-theater': { emoji: '🎭', bgColor: 'bg-walnut-600' },
  'paper-binoculars':          { emoji: '🔭', bgColor: 'bg-builder-400' },
  'foil-moon-rocks':           { emoji: '🌙', bgColor: 'bg-kraft-400' },
  'marble-ramp':               { emoji: '⚙️',  bgColor: 'bg-charcoal-700' },
}

const CLEANUP_LABEL: Record<string, string> = {
  low: 'Low', medium: 'Medium', high: 'High',
}

export const SUPERVISION_LABEL: Record<string, string> = {
  independent: 'Independent',
  check_in: 'Light Check-In',
  adult_assist: 'Adult Assist',
  full_supervision: 'Full Supervision',
}

const DIFFICULTY_LABEL: Record<string, string> = {
  easy: 'Easy', medium: 'Medium', advanced: 'Advanced',
}

export const MATCH_LABEL: Record<MatchType, 'Great Match' | 'Close Match' | 'Partial Match'> = {
  exact: 'Great Match',
  close: 'Close Match',
  fallback: 'Partial Match',
}

export function getProjectDisplay(slug: string): { emoji: string; bgColor: string } {
  return SLUG_DISPLAY[slug] ?? { emoji: '🎨', bgColor: 'bg-kraft-500' }
}

export function toDisplayProject(
  project: {
    id: string
    slug: string
    title: string
    description: string
    time_minutes: number
    age_min: number
    age_max: number
    cleanup_level: string
    supervision_level: string
    difficulty: string
  },
  matchType?: MatchType
): DisplayProject {
  const display = getProjectDisplay(project.slug)
  return {
    id: project.id,
    slug: project.slug,
    title: project.title,
    description: project.description,
    timeEstimate: `${project.time_minutes} min`,
    ageRange: `${project.age_min}–${project.age_max}`,
    cleanupLevel: CLEANUP_LABEL[project.cleanup_level] ?? project.cleanup_level,
    supervisionLevel: SUPERVISION_LABEL[project.supervision_level] ?? project.supervision_level,
    supervisionLevelRaw: project.supervision_level as SupervisionLevel,
    difficulty: DIFFICULTY_LABEL[project.difficulty] ?? project.difficulty,
    emoji: display.emoji,
    bgColor: display.bgColor,
    matchLabel: matchType ? MATCH_LABEL[matchType] : undefined,
  }
}
