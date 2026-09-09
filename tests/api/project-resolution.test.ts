import { describe, it, expect, vi } from 'vitest'
import { resolveProject } from '@/lib/projects/resolve'
import { isUuid, uuidSchema } from '@/lib/validation/identifiers'
describe('canonical project resolution', () => {
 it('accepts stored seed identifiers without RFC variant restrictions', () => {
  const id = '10000000-0000-0000-0000-000000000001'
  expect(uuidSchema.parse(id)).toBe(id); expect(isUuid(id)).toBe(true)
  expect(isUuid('x')).toBe(false)
 })
 it.each(['10000000-0000-0000-0000-000000000001', 'paper-boat'])('queries only the matching key column: %s', async key => {
  const maybeSingle = vi.fn().mockResolvedValue({ data: { id: 'canonical' }, error: null })
  const eq = vi.fn().mockReturnValue({ maybeSingle })
  const db = { from: vi.fn().mockReturnValue({ select: vi.fn().mockReturnValue({ eq }) }) }
  expect(await resolveProject(db as never, key)).toEqual({ id: 'canonical' })
  expect(eq).toHaveBeenCalledWith(isUuid(key) ? 'id' : 'slug', key)
 })
 it('rejects malformed keys without querying', async () => {
  const db = { from: vi.fn() }; await expect(resolveProject(db as never, 'x,or(id)')).rejects.toThrow(); expect(db.from).not.toHaveBeenCalled()
 })
 it('distinguishes absent rows from database failures', async () => {
  const maybeSingle = vi.fn().mockResolvedValueOnce({ data: null, error: null }).mockResolvedValueOnce({ data: null, error: { message: 'offline' } })
  const db = { from: () => ({ select: () => ({ eq: () => ({ maybeSingle }) }) }) }
  expect(await resolveProject(db as never, 'boat')).toBeNull(); await expect(resolveProject(db as never, 'boat')).rejects.toThrow()
 })
})
