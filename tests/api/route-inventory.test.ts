import { describe, expect, it } from 'vitest'
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import {
  type HttpMethod,
  extractMethods,
  findMatchingRoute,
  pathsMatch,
  scanBackendRoutes,
  scanFrontendFetches,
  scanSwiftEndpoints,
} from './inventory-scanner'

const APP_API_ROOT = join(process.cwd(), 'src/app/api')
const FRONTEND_ROOTS = [join(process.cwd(), 'src/app'), join(process.cwd(), 'src/components')]
const IOS_NATIVE_ROOT = join(process.cwd(), 'ios-native')

describe('endpoint contract: frontend fetch calls resolve to real routes', () => {
  const routes = scanBackendRoutes(APP_API_ROOT)
  const fetches = scanFrontendFetches(FRONTEND_ROOTS)
  const swiftEndpoints = scanSwiftEndpoints(IOS_NATIVE_ROOT)
  const clientCalls = [...fetches, ...swiftEndpoints]

  it('discovers a non-trivial route and fetch-call inventory', () => {
    expect(routes.size).toBeGreaterThan(15)
    expect(fetches.length).toBeGreaterThan(15)
  })

  it.each(clientCalls.map((f) => [`${f.method} ${f.path} (${f.file}:${f.line})`, f] as const))(
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
  it('scans Swift endpoint literals and interpolations with their initializer-scoped HTTP methods', () => {
    const root = mkdtempSync(join(tmpdir(), 'scraplab-swift-endpoints-'))
    const file = join(root, 'Endpoints.swift')
    writeFileSync(
      file,
      `
        enum Endpoints {
          static let misleadingNearby = Endpoint(path: "/api/projects", method: .get)

          static let activities = Endpoint(
            path: "/api/activities?featured=true&limit=10",
            method: .get
          )

          static func childProfile(id: UUID) -> Endpoint {
            Endpoint(method: .delete, path: "/api/child-profiles/\\(id)")
          }

          static let multiline = Endpoint(
            path: "/api/build-history/\\(id.uuidString)",
            method: .patch
          )
        }
      `,
    )

    try {
      const endpoints = scanSwiftEndpoints(root)
      expect(endpoints.map(({ path, method }) => ({ path, method }))).toEqual([
        { path: '/api/projects', method: 'GET' },
        { path: '/api/activities', method: 'GET' },
        { path: '/api/child-profiles/${id}', method: 'DELETE' },
        { path: '/api/build-history/${id.uuidString}', method: 'PATCH' },
      ])

      const routes = new Map<string, Set<HttpMethod>>([
        ['/api/projects', new Set(['GET'] as const)],
        ['/api/activities', new Set(['GET'] as const)],
        ['/api/child-profiles/[id]', new Set(['DELETE'] as const)],
        ['/api/build-history/[id]', new Set(['PATCH'] as const)],
      ])
      for (const endpoint of endpoints) {
        const match = findMatchingRoute(endpoint, routes)
        expect(match, `no backend route matches ${endpoint.method} ${endpoint.path}`).not.toBeNull()
        expect(match!.methods.has(endpoint.method)).toBe(true)
      }
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  it('rejects native billing checkout, billing portal, and webhook endpoints at scanner level', () => {
    const root = mkdtempSync(join(tmpdir(), 'scraplab-forbidden-swift-endpoints-'))
    const file = join(root, 'Endpoints.swift')
    writeFileSync(
      file,
      `
        enum Endpoints {
          static let checkout = Endpoint(path: "/api/checkout", method: .post)
          static let billingPortal = Endpoint(path: "/api/billing/portal", method: .post)
          static let revenueCatWebhook = Endpoint(path: "/api/webhooks/revenuecat", method: .post)
        }
      `,
    )

    try {
      const endpoints = scanSwiftEndpoints(root)
      const forbidden = endpoints.filter(({ path }) =>
        path === '/api/checkout' || path === '/api/billing/portal' || path.includes('/webhooks/'),
      )
      expect(forbidden.map(({ method, path }) => `${method} ${path}`)).toEqual([
        'POST /api/checkout',
        'POST /api/billing/portal',
        'POST /api/webhooks/revenuecat',
      ])
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  it('returns an empty Swift inventory when ios-native is absent', () => {
    const missingRoot = join(tmpdir(), `scraplab-missing-ios-native-${process.pid}`)
    rmSync(missingRoot, { recursive: true, force: true })
    expect(scanSwiftEndpoints(missingRoot)).toEqual([])
  })

  it('ignores generated SwiftPM build output', () => {
    const root = mkdtempSync(join(tmpdir(), 'scraplab-swift-build-output-'))
    const buildRoot = join(root, '.build', 'debug')
    mkdirSync(buildRoot, { recursive: true })
    writeFileSync(
      join(buildRoot, 'Generated.swift'),
      'let forbidden = Endpoint(path: "/api/does-not-exist", method: .get)',
    )

    try {
      expect(scanSwiftEndpoints(root)).toEqual([])
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

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
