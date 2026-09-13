#!/usr/bin/env node
import { readFileSync } from 'node:fs'
import { join } from 'node:path'

const repoRoot = process.cwd()
const webDisplayPath = join(repoRoot, 'src/lib/display.ts')
const nativeLogicPath = join(repoRoot, 'ios-native/Packages/ScrapLabCore/Sources/ScrapLabModels/NativeLogic.swift')

function extractWebSlugs(source) {
  const block = source.match(/const SLUG_DISPLAY:[\s\S]*?= \{([\s\S]*?)\n\}/)?.[1]
  if (!block) throw new Error('Could not find SLUG_DISPLAY block in src/lib/display.ts')
  return [...block.matchAll(/'([^']+)'\s*:/g)].map((m) => m[1]).sort()
}

function extractNativeSlugs(source) {
  const block = source.match(/public static func theme\(for slug: String\)[\s\S]*?switch slug \{([\s\S]*?)\n\s*default:/)?.[1]
  if (!block) throw new Error('Could not find ProjectDisplayTheme switch in NativeLogic.swift')
  return [...block.matchAll(/case "([^"]+)"/g)].map((m) => m[1]).sort()
}

function assertSameSlugs(webSlugs, nativeSlugs) {
  const webOnly = webSlugs.filter((slug) => !nativeSlugs.includes(slug))
  const nativeOnly = nativeSlugs.filter((slug) => !webSlugs.includes(slug))
  if (webOnly.length || nativeOnly.length) {
    throw new Error(`Slug map mismatch. Web only: ${webOnly.join(', ') || 'none'}. Native only: ${nativeOnly.join(', ') || 'none'}.`)
  }
}

async function auditLiveRows(slugs) {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!supabaseUrl || !serviceRoleKey) {
    console.log(`Native slug map is internally consistent (${slugs.length} slugs). Live Supabase row audit skipped: set NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.`)
    return
  }

  const endpoint = new URL('/rest/v1/projects', supabaseUrl)
  endpoint.searchParams.set('select', 'slug')
  endpoint.searchParams.set('slug', `in.(${slugs.join(',')})`)

  const response = await fetch(endpoint, {
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
  })
  if (!response.ok) {
    const body = await response.text()
    throw new Error(`Supabase slug audit failed: ${response.status} ${response.statusText} ${body}`)
  }
  const rows = await response.json()
  const found = rows.map((row) => row.slug).sort()
  const missing = slugs.filter((slug) => !found.includes(slug))
  if (missing.length) {
    throw new Error(`Missing project rows for native display slugs: ${missing.join(', ')}`)
  }
  console.log(`Native slug map is internally consistent and all ${slugs.length} slugs exist in Supabase.`)
}

const webSlugs = extractWebSlugs(readFileSync(webDisplayPath, 'utf8'))
const nativeSlugs = extractNativeSlugs(readFileSync(nativeLogicPath, 'utf8'))
assertSameSlugs(webSlugs, nativeSlugs)
await auditLiveRows(webSlugs)
