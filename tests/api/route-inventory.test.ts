import { describe, expect, it } from 'vitest'
import { join } from 'node:path'
import {
  extractMethods,
  findMatchingRoute,
  pathsMatch,
  scanBackendRoutes,
  scanFrontendFetches,
} from './inventory-scanner'

const APP_API_ROOT = join(process.cwd(), 'src/app/api')
const FRONTEND_ROOTS = [join(process.cwd(), 'src/app'), join(process.cwd(), 'src/components')]

describe('endpoint contract: frontend fetch calls resolve to real routes', () => {
  const routes = scanBackendRoutes(APP_API_ROOT)
  const fetches = scanFrontendFetches(FRONTEND_ROOTS)

  it('discovers a non-trivial route and fetch-call inventory', () => {
    expect(routes.size).toBeGreaterThan(15)
    expect(fetches.length).toBeGreaterThan(15)
  })

  it.each(fetches.map((f) => [`${f.method} ${f.path} (${f.file}:${f.line})`, f] as const))(
    '%s matches an exported route method',
    (_label, fetchCall) => {
      const match = findMatchingRoute(fetchCall, routes)
      expect(match, `no route file matches path ${fetchCall.path}`).not.toBeNull()
      expect(
        match!.methods.has(fetchCall.method),
        `route ${match!.path} does not export ${fetchCall.method} (has: ${[...match!.methods].join(', ')})`,
      ).toBe(true)
    },
  )
})

describe('inventory scanner regression guard', () => {
  it('extracts every exported HTTP method from a route file', () => {
    const source = `
      export async function GET(request: NextRequest) {}
      export async function POST(request: NextRequest) {}
    `
    expect(extractMethods(source)).toEqual(new Set(['GET', 'POST']))
  })

  it('matches dynamic segments in both directions', () => {
    expect(pathsMatch('/api/child-profiles/${id}', '/api/child-profiles/[id]')).toBe(true)
    expect(pathsMatch('/api/child-profiles', '/api/child-profiles/[id]')).toBe(false)
    expect(pathsMatch('/api/activities', '/api/activity-recommendations')).toBe(false)
  })

  it('catches a fetch call whose method was removed from the route (deliberate missing-method fixture)', () => {
    const routes = new Map([['/api/saved-projects', new Set(['GET'] as const)]])
    const match = findMatchingRoute({ path: '/api/saved-projects', method: 'POST' }, routes)
    expect(match).not.toBeNull()
    expect(match!.methods.has('POST')).toBe(false)
  })

  it('catches a fetch call whose path no longer exists (deliberate missing-route fixture)', () => {
    const routes = new Map([['/api/saved-projects', new Set(['GET', 'POST'] as const)]])
    const match = findMatchingRoute({ path: '/api/unsaved-projects', method: 'GET' }, routes)
    expect(match).toBeNull()
  })
})
