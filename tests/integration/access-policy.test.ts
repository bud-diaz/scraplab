import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
const sql = (name: string) => readFileSync(`supabase/migrations/${name}.sql`, 'utf8')
describe('persistence SQL security invariants (staging execution still required)', () => {
 it('revokes inherited profile and managed table writes, enforces child ownership', () => {
  const s = sql('008_endpoint_access_hardening')
  expect(s).toMatch(/revoke insert, update, delete on public.profiles from public, anon, authenticated/i)
  expect(s).toContain('child_profile_id, user_id'); expect(s).toContain('references public.child_profiles(id, user_id)')
  expect(s).toContain('for update'); expect(s).toContain('Saved project limit reached')
  expect(s.indexOf('if found then return')).toBeLessThan(s.indexOf('Saved project limit reached'))
 })
 it('serializes starts, reconciles duplicates, locks progress, preserves completion timestamps', () => {
  const s = sql('009_build_progress')
  expect(s).toContain('row_number() over'); expect(s).toContain("where completion_status = 'started'")
  expect(s).toContain('for update'); expect(s).toContain('coalesce(b.completed_at, now())')
  expect(s).toContain('Terminal build cannot change'); expect(s).toContain('Finish the last step first')
  expect(s).toContain('from public, anon, authenticated')
 })
 it('inventory uses atomic conflict update with presence checks, not default overwrite', () => {
  const s = sql('013_inventory_persistence')
  expect(s).toContain('on conflict (user_id, material_id) do update')
  expect(s).toContain("p_patch ? 'stapleFlag'"); expect(s).toContain("p_patch ? 'confidenceScore'")
  expect(s).toContain("v_plan <> 'plus'"); expect(s).toContain('from public, anon, authenticated')
 })
})
