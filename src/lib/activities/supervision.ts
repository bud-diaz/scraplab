import type { SupervisionLevel } from '@/types'

// activities.supervision_level was seeded with different, non-canonical
// labels than projects.supervision_level ('some-help', 'adult-needed' vs
// the canonical independent/check_in/adult_assist/full_supervision enum).
// Mapped conservatively — never toward *less* supervision than the label
// implies — so this can never silently understate a safety requirement.
const ACTIVITY_SUPERVISION_MAP: Record<string, SupervisionLevel> = {
  independent: 'independent',
  'some-help': 'adult_assist',
  'adult-needed': 'full_supervision',
}

/** Returns null for any label outside the known set, rather than guessing. */
export function normalizeActivitySupervisionLevel(raw: string): SupervisionLevel | null {
  return ACTIVITY_SUPERVISION_MAP[raw] ?? null
}
