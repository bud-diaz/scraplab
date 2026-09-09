import { describe, expect, it } from 'vitest'
import { normalizeActivitySupervisionLevel } from '@/lib/activities/supervision'

describe('normalizeActivitySupervisionLevel', () => {
  it('maps known activity labels to the canonical project enum', () => {
    expect(normalizeActivitySupervisionLevel('independent')).toBe('independent')
    expect(normalizeActivitySupervisionLevel('some-help')).toBe('adult_assist')
    expect(normalizeActivitySupervisionLevel('adult-needed')).toBe('full_supervision')
  })

  it('fails safe (null) for an unrecognized label rather than guessing', () => {
    expect(normalizeActivitySupervisionLevel('totally-unknown')).toBeNull()
    expect(normalizeActivitySupervisionLevel('')).toBeNull()
  })
})
