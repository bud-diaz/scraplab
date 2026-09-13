#!/usr/bin/env node
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

const baseURL = process.env.SCRAPLAB_FIXTURE_BASE_URL ?? process.env.SCRAPLAB_BASE_URL ?? 'https://scraplab-inky.vercel.app'
const token = process.env.SCRAPLAB_FIXTURE_BEARER_TOKEN ?? process.env.SCRAPLAB_BEARER_TOKEN
const outDir = process.env.SCRAPLAB_FIXTURE_OUT_DIR ?? path.join('ios-native', 'Packages', 'ScrapLabCore', 'Tests', 'ScrapLabModelsTests', 'Fixtures')

const publicRequests = [
  ['activities', '/api/activities?featured=true&limit=3'],
  ['projects', '/api/projects'],
  ['materials', '/api/materials'],
]

const protectedRequests = [
  ['access', '/api/me/access'],
  ['household-inventory', '/api/household-inventory'],
  ['build-history', '/api/build-history'],
  ['saved-projects', '/api/saved-projects'],
  ['child-profiles', '/api/child-profiles'],
  ['mystery-materials', '/api/mystery-materials'],
]

function usage() {
  console.log(`Capture live ScrapLab API payloads into Swift fixture JSON files.

Env:
  SCRAPLAB_FIXTURE_BASE_URL       Base URL to fetch from (default: ${baseURL})
  SCRAPLAB_FIXTURE_BEARER_TOKEN   Optional Supabase access token for protected routes
  SCRAPLAB_FIXTURE_OUT_DIR        Output dir (default: ${outDir})

Behavior:
  - Always fetches public list routes.
  - Fetches detail routes only when public list payloads provide IDs/slugs.
  - Skips protected routes unless a bearer token is provided.
  - Never needs service-role keys or local secrets.
`)
}

if (process.argv.includes('--help') || process.argv.includes('-h')) {
  usage()
  process.exit(0)
}

async function fetchJSON(route, auth = false) {
  const headers = { Accept: 'application/json' }
  if (auth && token) headers.Authorization = `Bearer ${token}`
  const response = await fetch(new URL(route, baseURL), { headers })
  const text = await response.text()
  let json
  try {
    json = text ? JSON.parse(text) : {}
  } catch {
    throw new Error(`${route} returned non-JSON (${response.status}): ${text.slice(0, 160)}`)
  }
  if (!response.ok) {
    throw new Error(`${route} failed with ${response.status}: ${JSON.stringify(json).slice(0, 240)}`)
  }
  return json
}

async function writeFixture(name, json) {
  await writeFile(path.join(outDir, `${name}.json`), `${JSON.stringify(json, null, 2)}\n`)
  console.log(`wrote ${name}.json`)
}

await mkdir(outDir, { recursive: true })
const captured = new Map()

for (const [name, route] of publicRequests) {
  captured.set(name, await fetchJSON(route))
  await writeFixture(name, captured.get(name))
}

const firstActivity = captured.get('activities')?.activities?.[0]
if (firstActivity?.slug || firstActivity?.id) {
  await writeFixture('activity-detail', await fetchJSON(`/api/activities/${encodeURIComponent(firstActivity.slug ?? firstActivity.id)}`))
} else {
  console.warn('skipped activity-detail.json: no activity id/slug in activities response')
}

const firstProject = captured.get('projects')?.projects?.[0]
if (firstProject?.slug || firstProject?.id) {
  await writeFixture('project-detail', await fetchJSON(`/api/projects/${encodeURIComponent(firstProject.slug ?? firstProject.id)}`))
} else {
  console.warn('skipped project-detail.json: no project id/slug in projects response')
}

if (!token) {
  console.warn('skipped protected fixtures: set SCRAPLAB_FIXTURE_BEARER_TOKEN to capture authenticated routes')
} else {
  for (const [name, route] of protectedRequests) {
    await writeFixture(name, await fetchJSON(route, true))
  }
}

console.log('done')
