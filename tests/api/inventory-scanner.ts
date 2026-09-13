import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'

export const HTTP_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] as const
export type HttpMethod = (typeof HTTP_METHODS)[number]

export interface FrontendFetch {
  file: string
  line: number
  path: string
  method: HttpMethod
}

const IGNORED_DIRECTORIES = new Set(['.build', '.git', '.next', 'DerivedData', 'node_modules'])

function walk(dir: string, out: string[] = []): string[] {
  for (const entry of readdirSync(dir)) {
    if (IGNORED_DIRECTORIES.has(entry)) continue

    const full = join(dir, entry)
    const stat = statSync(full)
    if (stat.isDirectory()) walk(full, out)
    else out.push(full)
  }
  return out
}

/** Maps an app-router `route.ts` file path to its URL path, e.g.
 * src/app/api/child-profiles/[id]/route.ts -> /api/child-profiles/[id] */
export function routeFileToPath(root: string, file: string): string {
  const rel = relative(root, file).replace(/\\/g, '/')
  const withoutFile = rel.replace(/\/route\.ts$/, '')
  return '/' + withoutFile
}

export function extractMethods(source: string): Set<HttpMethod> {
  const methods = new Set<HttpMethod>()
  const fnPattern = /export\s+async\s+function\s+(GET|POST|PUT|PATCH|DELETE)\s*\(/g
  const constPattern = /export\s+const\s+(GET|POST|PUT|PATCH|DELETE)\s*=/g
  for (const pattern of [fnPattern, constPattern]) {
    let match: RegExpExecArray | null
    while ((match = pattern.exec(source))) {
      methods.add(match[1] as HttpMethod)
    }
  }
  return methods
}

/** Scans `src/app/api/**\/route.ts` and returns URL path -> exported methods. */
export function scanBackendRoutes(appApiRoot: string): Map<string, Set<HttpMethod>> {
  const routes = new Map<string, Set<HttpMethod>>()
  const files = walk(appApiRoot).filter((f) => f.endsWith('route.ts'))
  for (const file of files) {
    const path = routeFileToPath(join(appApiRoot, '..'), file)
    const methods = extractMethods(readFileSync(file, 'utf8'))
    routes.set(path, methods)
  }
  return routes
}

const FETCH_CALL = /fetch\(\s*(`([^`]*)`|'([^']*)'|"([^"]*)")\s*(,\s*\{([\s\S]*?)\})?\s*\)/g

/** Scans a set of directories for `fetch('/api/...')` call sites. */
export function scanFrontendFetches(roots: string[]): FrontendFetch[] {
  const results: FrontendFetch[] = []
  for (const root of roots) {
    const files = walk(root).filter((f) => /\.(ts|tsx)$/.test(f) && !f.includes('/api/'))
    for (const file of files) {
      const source = readFileSync(file, 'utf8')
      let match: RegExpExecArray | null
      FETCH_CALL.lastIndex = 0
      while ((match = FETCH_CALL.exec(source))) {
        const rawPath = match[2] ?? match[3] ?? match[4]
        if (!rawPath.startsWith('/api')) continue
        const optionsBlock = match[6] ?? ''
        const methodMatch = optionsBlock.match(/method:\s*['"`](GET|POST|PUT|PATCH|DELETE)['"`]/)
        const method = (methodMatch?.[1] as HttpMethod) ?? 'GET'
        const path = rawPath.split('?')[0]
        const line = source.slice(0, match.index).split('\n').length
        results.push({ file, line, path, method })
      }
    }
  }
  return results
}

const SWIFT_ENDPOINT_CALL = /\bEndpoint\s*\(/g
const SWIFT_API_PATH_ARGUMENT = /\bpath\s*:\s*"(\/api\/(?:\\.|[^"\\])*)"/
const SWIFT_HTTP_METHOD_ARGUMENT = /\b(?:httpMethod|method)\s*:\s*(?:HttpMethod\s*\.\s*|\.\s*)?(GET|POST|PUT|PATCH|DELETE)\b/i

function findSwiftCallEnd(source: string, openParenIndex: number): number {
  let depth = 0
  let quote: '"' | null = null
  let escaped = false

  for (let i = openParenIndex; i < source.length; i++) {
    const char = source[i]
    if (quote) {
      if (escaped) {
        escaped = false
      } else if (char === '\\') {
        escaped = true
      } else if (char === quote) {
        quote = null
      }
      continue
    }

    if (char === '"') {
      quote = '"'
    } else if (char === '(') {
      depth += 1
    } else if (char === ')') {
      depth -= 1
      if (depth === 0) return i + 1
    }
  }
  return -1
}

function normalizeSwiftAPIPath(path: string): string {
  return path.replace(/\\\(([^)]*)\)/g, '${$1}').split('?')[0]
}

/** Scans Swift `Endpoint(...)` declarations for `/api/...` literals paired with
 * the method inside the same initializer call. This deliberately avoids the old
 * nearest-token heuristic, which could pair a path with the wrong nearby method
 * after harmless formatting or comments. */
export function scanSwiftEndpoints(root: string): FrontendFetch[] {
  if (!existsSync(root)) return []

  const results: FrontendFetch[] = []
  const files = walk(root).filter(
    (file) => file.endsWith('.swift') && !file.replace(/\\/g, '/').includes('/Tests/'),
  )
  for (const file of files) {
    const source = readFileSync(file, 'utf8')
    let endpointMatch: RegExpExecArray | null
    SWIFT_ENDPOINT_CALL.lastIndex = 0
    while ((endpointMatch = SWIFT_ENDPOINT_CALL.exec(source))) {
      const openParenIndex = endpointMatch.index + endpointMatch[0].lastIndexOf('(')
      const callEnd = findSwiftCallEnd(source, openParenIndex)
      if (callEnd === -1) continue

      const callSource = source.slice(endpointMatch.index, callEnd)
      const pathMatch = callSource.match(SWIFT_API_PATH_ARGUMENT)
      const methodMatch = callSource.match(SWIFT_HTTP_METHOD_ARGUMENT)
      if (!pathMatch || !methodMatch) continue

      const line = source.slice(0, endpointMatch.index).split('\n').length
      results.push({
        file,
        line,
        path: normalizeSwiftAPIPath(pathMatch[1]),
        method: methodMatch[1].toUpperCase() as HttpMethod,
      })
    }
  }
  return results
}

/** Compares a concrete frontend path (may contain `${...}` template segments)
 * against a route path (may contain `[param]` dynamic segments). */
export function pathsMatch(frontendPath: string, routePath: string): boolean {
  const a = frontendPath.split('/').filter(Boolean)
  const b = routePath.split('/').filter(Boolean)
  if (a.length !== b.length) return false
  return a.every((segment, i) => {
    const routeSegment = b[i]
    const isDynamic = /^\[.+\]$/.test(routeSegment) || /^\$\{.*\}$/.test(segment)
    return isDynamic || segment === routeSegment
  })
}

export function findMatchingRoute(
  fetchCall: Pick<FrontendFetch, 'path' | 'method'>,
  routes: Map<string, Set<HttpMethod>>,
): { path: string; methods: Set<HttpMethod> } | null {
  for (const [routePath, methods] of routes) {
    if (pathsMatch(fetchCall.path, routePath)) {
      return { path: routePath, methods }
    }
  }
  return null
}
