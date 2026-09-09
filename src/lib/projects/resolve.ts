import type { SupabaseClient } from '@supabase/supabase-js'
import { isUuid } from '@/lib/validation/identifiers'

// Deliberately conservative: lowercase alphanumeric segments separated by
// single hyphens, matching how every seeded/generated project slug looks.
// Anything else (commas, parens, whitespace, `.or(...)`-shaped strings)
// is rejected before it ever reaches a query, closing the injection-shaped
// pattern possible with raw `.or(\`id.eq.${id},slug.eq.${id}\`)` filters.
const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/

/**
 * Resolves a project by UUID `id` or by `slug`, branching to exactly one
 * `.eq()` filter rather than interpolating the key into a `.or()` string.
 * Returns null for "no such project", and throws for actual DB failures —
 * callers should turn the former into a 404 and the latter into a 500.
 */
export async function resolveProject<T = Record<string, unknown>>(
  db: SupabaseClient,
  key: string,
  select = '*',
): Promise<T | null> {
  const column = isUuid(key) ? 'id' : 'slug'
  if (column === 'slug' && !SLUG_PATTERN.test(key)) {
    throw new Error(`Invalid project identifier: ${key}`)
  }

  const { data, error } = await db.from('projects').select(select).eq(column, key).maybeSingle()
  if (error) {
    throw new Error(error.message)
  }
  return (data as T | null) ?? null
}
