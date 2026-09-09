import { z } from 'zod'

// Postgres `uuid` columns accept any syntactically valid 8-4-4-4-12 hex
// string, including non-RFC-4122 values like the seed data's
// 10000000-0000-0000-0000-000000000001 (version/variant nibbles both 0).
// zod's built-in .uuid() is RFC-4122-strict and rejects those, so this
// mirrors Postgres's actual acceptance rules instead.
const UUID_PATTERN = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/

export function isUuid(value: string): boolean {
  return UUID_PATTERN.test(value)
}

export const uuidSchema = z.string().regex(UUID_PATTERN, 'Invalid UUID')

// For text-keyed lookups (e.g. activities.id/slug) where there's no
// UUID-vs-slug distinction to branch on, but the same
// `.or(\`id.eq.${x},slug.eq.${x}\`)` string-interpolation risk applies.
// Restricts route params to a safe charset before they reach a query.
const SAFE_SEGMENT_PATTERN = /^[a-zA-Z0-9_-]+$/

export function isSafeRouteSegment(value: string): boolean {
  return SAFE_SEGMENT_PATTERN.test(value)
}
