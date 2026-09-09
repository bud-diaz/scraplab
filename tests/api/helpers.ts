import { afterEach, beforeEach } from 'vitest'

const REAL_ENV_KEYS = [
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  'SUPABASE_SERVICE_ROLE_KEY',
  'STRIPE_SECRET_KEY',
  'STRIPE_WEBHOOK_SECRET',
  'GOOGLE_AI_API_KEY',
  'REVENUECAT_SECRET_API_KEY',
  'REVENUECAT_WEBHOOK_SECRET',
]

// Route handler tests mock @/lib/db/client, @/lib/stripe, etc. directly, so no
// real credentials should ever be read. Strip anything loaded from a real
// .env.local so a missing mock fails loudly instead of hitting production.
const savedRealEnv: Record<string, string | undefined> = {}

beforeEach(() => {
  for (const key of REAL_ENV_KEYS) {
    savedRealEnv[key] = process.env[key]
    delete process.env[key]
  }
})

afterEach(() => {
  for (const key of REAL_ENV_KEYS) {
    if (savedRealEnv[key] === undefined) delete process.env[key]
    else process.env[key] = savedRealEnv[key]
  }
})
