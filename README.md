# ScrapLab

**Build More. Buy Less.**

ScrapLab is a kid-friendly creativity assistant that turns everyday household materials — cardboard tubes, tape, plastic cups, egg cartons, bottle caps — into safe, age-appropriate build projects. Parents and caregivers tell ScrapLab what they already have on hand, and the app recommends achievable projects with step-by-step instructions, instead of sending them off to search Pinterest or buy another craft kit.

The product is **inventory-first**: it starts from the junk drawer, not from a content library.

---

## Table of Contents

- [Why ScrapLab](#why-scraplab)
- [Core Product Principles](#core-product-principles)
- [Who It's For](#who-its-for)
- [How It Works](#how-it-works)
- [Feature Tour](#feature-tour)
- [Safety Model](#safety-model)
- [Free vs. Plus](#free-vs-plus)
- [Application Architecture](#application-architecture)
- [Data Model](#data-model)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [Non-Goals](#non-goals)

---

## Why ScrapLab

Kids collect random objects for imagined future projects. Parents then run into the same wall:

- they don't know what to actually make with what's lying around
- they don't want to buy another single-use craft kit
- they don't have time to sift through Pinterest-style content
- they need something **safe** and **age-appropriate**, fast
- they want creative enrichment without adding more clutter to the house

ScrapLab closes that gap by treating "what materials do I have?" as the starting question, and turning the answer into a ranked list of buildable projects in under a minute.

## Core Product Principles

1. **Inventory First** — recommendations start from available materials (`cardboard tube + tape + plastic cup + markers` → rocket ship, binoculars, mini puppet, marble launcher), not from browsing a craft catalog.
2. **Safety by Design** — every project is age-filtered and safety-aware: no open flame, no dangerous chemicals, no sharp tools for younger age groups, clear supervision indicators.
3. **Fast Parent UX** — photo upload or tap-to-select material input, no lengthy forms.
4. **Kid Delight** — playful project naming, visual inspiration, and a sense of accomplishment on completion, not a dry instruction sheet.

## Who It's For

**Primary:** parents and caregivers of children ages 3–10 — busy parents, budget-conscious families, apartment dwellers with limited storage, rainy-day activity seekers, and parents encouraging screen-light creative play.

**Secondary:** educators — teachers, daycare providers, homeschool families, and after-school programs looking for low-cost, low-prep activities.

## How It Works

1. **Tell ScrapLab what you have.** Snap a photo of your materials or manually pick from a categorized library.
2. **Confirm detected materials.** Computer vision detection is shown as a checklist the parent can correct — remove false positives, add anything missed — before recommendations are generated.
3. **Get ranked project matches.** Projects are scored by material compatibility, age fit, and available substitutions, from exact matches down to creative fallback ideas.
4. **See the real cost up front.** Every project shows its time estimate, mess level, and supervision requirement before you commit to it.
5. **Build it, step by step.** Walk through instructions at your own pace, mark progress, and save or complete the build.
6. **ScrapLab remembers.** Household staples, saved favorites, and build history make future recommendations more relevant.

## Feature Tour

The features below map directly to what's implemented in `src/app` and `src/lib`.

### Material Input
- **Manual Material Picker** (`create/manual`) — browse and search a categorized material library, select what's on hand.
- **Photo Material Recognition** (`create/scan`, `api/scan-materials`) — upload a photo; an AI vision step detects candidate materials, which the user confirms or corrects before matching runs.
- **Mystery Materials mode** (`build/mystery`, `api/mystery-materials`) — a randomized/challenge variant of material input for surprise builds.

### Recommendation Engine (`lib/recommendations`)
- Deterministic, explainable matching against a structured project database — not free-form AI generation of instructions.
- Match tiers: `exact` → `close` → `fallback`, so a project list is never empty just because one material is missing.
- **Material substitution support** (e.g. googly eyes → drawn eyes, bottle caps → buttons) fills gaps in an otherwise-good match.
- Filters recommendations by child age, time budget, cleanup tolerance, and supervision level.

### Project Reality Indicators
Every project surfaces, up front and not buried in fine print:
- **Time estimate** (quick win vs. weekend build)
- **Cleanup level** (`low` / `medium` / `high`)
- **Supervision level** (`independent` / `check_in` / `adult_assist` / `full_supervision`)
- **Difficulty** (`easy` / `medium` / `advanced`)

### Guided Build Experience (`build/[id]`, `build/[id]/complete`)
- Step-by-step instructions with per-step tips and safety notes.
- Progress tracking through `BuildHistory` (`started` / `completed` / `abandoned`).
- Save-for-later via `SavedProject`.

### Discovery & Library
- **Explore** (`explore`, `explore/[slug]`) — curated activity library organized by category, theme, and skill tags, independent of a user's current material inventory.
- **Challenges** (`challenges`) — themed/seasonal challenge packs and quest-chain activities.
- **Library** (`library`) — saved and completed projects in one place.

### Household & Profile Memory
- **Household Inventory** — tracks materials by source (`manual` / `detected` / `saved`) and lets users flag recurring items as household staples, improving future matches without re-scanning every time.
- **Child Profiles** — per-child age tracking so recommendations and history can be personalized within a family.
- **Onboarding** (`onboarding`) — first-run flow to set up a profile and preferences.

### Account & Billing
- Supabase-backed auth (`auth`, `auth/callback`) and profile management (`profile`).
- Stripe-powered subscription checkout, billing portal, and webhook handling (`api/checkout`, `api/billing/portal`, `api/webhooks/stripe`) backing the **ScrapLab Plus** plan.
- A plan-aware access layer (`lib/access`) enforces daily recommendation limits, photo-scan gating, child-profile caps, and saved-project caps per plan.

## Safety Model

Safety is enforced structurally, not left to AI judgement:

- **Hard restrictions:** fire, knives, electrical work, toxic substances, chemical reactions, unsupervised hazardous builds.
- **Safety labels** on every project: toddler-safe, supervised, or adult-assistance-required.
- AI is used only for *secondary* enhancement — project naming, alternate variations, encouragement copy, visual descriptions — never for unconstrained generation of build instructions for young children, to avoid unsafe hallucinations.

## Free vs. Plus

| | Free | ScrapLab Plus |
|---|---|---|
| Daily project recommendations | 3/day | Unlimited |
| Manual material picker | ✅ | ✅ |
| Photo material recognition | — | ✅ |
| Child profiles | 1 | Up to 10 |
| Saved projects | 10 | Unlimited |
| Curated project library | Core library | Full library |

Free is designed to be genuinely useful on its own — the goal is habit formation and organic sharing, not a crippled trial. Plus is aimed at families who are already getting value and want convenience (photo scanning), depth (more child profiles, full history), and expanded creative content.

## Application Architecture

ScrapLab is a single Next.js (App Router) application combining the web UI and its API in one deployable unit.

- **UI layer** (`src/app/**/page.tsx`) — server/client React components for each screen (home, create flow, build flow, explore, library, profile, subscription).
- **API layer** (`src/app/api/**/route.ts`) — REST-style route handlers for materials, activities, projects, recommendations, household inventory, child profiles, saved projects, build history, material scanning, and Stripe billing/webhooks.
- **Domain logic** (`src/lib`) — framework-agnostic modules: `recommendations` (matching engine), `access` (plan/limit enforcement), `safety` (safety rule checks), `ai` (vision-based material detection and AI-assisted suggestions), `db` (Supabase client + auth helpers).
- **Persistence** — Supabase (Postgres + Storage), with SQL migrations in `supabase/migrations` and seed data in `supabase/seed.sql`.
- **Design system** — shared UI primitives in `src/components/ui` (badges, chips, cards, progress steppers) and layout shells in `src/components/layout`, following the tone/visual guidelines in `SCRAPLAB_UI_DESIGN_SYSTEM.md` and `SCRAPLAB_BRANDING_SYSTEM.md`.

## Data Model

Core entities (see `src/types/index.ts` and `supabase/migrations`):

- **UserProfile** — account + plan (`free` / `plus`).
- **ChildProfile** — per-child name/age within a household.
- **Material** — canonical material with aliases, category, icon.
- **Project** — a buildable project: age range, time, difficulty, cleanup level, supervision level, safety notes, ordered `BuildStep[]` instructions.
- **ProjectMaterial** — required/optional materials for a project, with quantity notes.
- **MaterialSubstitution** — source → replacement material mappings used by the matching engine.
- **SavedProject** / **BuildHistory** — a user's bookmarks and in-progress/completed builds.
- **HouseholdInventory** — a user's known materials, with confidence score, source, and staple flag.
- **Activity** — a broader library entity (used by Explore/Challenges) carrying richer metadata: category, energy level, attention-span fit, theme/skill tags, quest-chain fields, and content-pack/seasonal flags — see `scraplab_activity_schema.json` for the full schema.

## Tech Stack

- **Frontend:** Next.js 16 (App Router), React 19, TypeScript, Tailwind CSS v4
- **UI utilities:** `class-variance-authority`, `clsx`, `tailwind-merge`, `lucide-react`
- **Backend:** Next.js API routes
- **Database & Storage:** Supabase (Postgres + Storage)
- **AI:** Google Gemini (`@google/genai`) for material vision detection and AI-assisted suggestion copy
- **Payments:** Stripe (`stripe`) — subscriptions, billing portal, webhooks
- **Validation:** Zod
- **Tooling:** ESLint, TypeScript
- **iOS app:** Capacitor (remote-URL mode, wrapping this same web app) + RevenueCat for Apple In-App Purchase

## Getting Started

```bash
npm install
cp .env.example .env.local   # then fill in the values below
npm run dev
```

The app runs at `http://localhost:3000`.

Other scripts:

```bash
npm run build   # production build
npm run start   # run the production build
npm run lint     # lint the codebase
```

Database schema and seed data live under `supabase/` — apply `supabase/migrations/*.sql` (in order) to a Supabase project, then optionally run `supabase/seed.sql` for sample data.

## Environment Variables

See `.env.example` for the full list with setup notes. At a minimum you'll need:

| Variable | Purpose |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase project connection (client) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service-role access (server) |
| `GOOGLE_AI_API_KEY` | Google AI Studio key for AI-generated activity suggestions (Gemini) |
| `STRIPE_SECRET_KEY` / `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Stripe API keys |
| `STRIPE_PLUS_PRICE_ID` | Price ID for the ScrapLab Plus recurring plan |
| `STRIPE_WEBHOOK_SECRET` | Signing secret for the Stripe webhook endpoint |
| `NEXT_PUBLIC_REVENUECAT_IOS_API_KEY` / `REVENUECAT_SECRET_API_KEY` / `REVENUECAT_WEBHOOK_SECRET` | RevenueCat keys for the iOS app's Apple In-App Purchase subscription |

## iOS App

The iOS app is a Capacitor shell around this same Next.js app, configured in
"remote URL" mode — the native WKWebView loads the live production
deployment rather than a bundled static export, since the app relies on
Server Components and API routes with a service-role secret that must never
ship client-side. Native functionality (camera, Apple In-App Purchase,
haptics, share, safe-area/status bar handling) is layered on top via
Capacitor plugins, all under `src/lib/native/` and `src/components/native/`.

```bash
npm install                 # installs both web and Capacitor deps
npx cap sync ios            # regenerate ios/ from installed plugins
npx cap open ios            # open the Xcode project (requires Xcode, macOS)
```

For local development against `next dev` instead of production, use
`CAP_ENV=dev npx cap sync ios` (see `capacitor.config.ts`). Camera and Apple
In-App Purchase both require a physical iOS device to test — the Simulator
has no real camera and cannot complete real StoreKit purchases without a
Sandbox Tester account.

Subscriptions use a separate purchase path from the web app: web checkout
still goes through Stripe (`api/webhooks/stripe`), while the iOS app
purchases through Apple via RevenueCat (`api/webhooks/revenuecat`,
`api/me/sync-revenuecat`). Both write to the same `profiles.plan` column,
guarded by `profiles.plan_source` so the two webhooks can't clobber each
other's grant for the same user (see `supabase/migrations/007_ios_iap.sql`).

## Project Structure

```
src/
  app/
    api/            # REST route handlers (materials, projects, recommendations, billing, etc.)
    create/         # material input flow (manual picker, photo scan, results)
    build/          # guided build + completion flow, mystery mode
    explore/        # curated activity library
    challenges/     # themed/seasonal challenge packs
    library/        # saved + completed projects
    onboarding/     # first-run setup
    profile/        # account & child profile management
    subscription/, upgrade/  # billing UI
  components/
    cards/          # feature-level cards (activity, project, progress, etc.)
    layout/         # app shell, nav
    ui/             # shared primitives (badges, chips, buttons, steppers)
  lib/
    recommendations/  # matching engine
    access/           # plan limits & gating
    safety/           # safety rule checks
    ai/               # vision detection + AI-assisted suggestions
    db/               # Supabase client & auth helpers
  types/            # shared TypeScript types
supabase/
  migrations/       # SQL schema migrations
  seed.sql          # sample data
```

Additional planning documents in the repo root go deeper on strategy and design:

- `SCRAPLAB_PROJECT_SCOPE.md` — full product scope, MVP definition, and phased roadmap
- `SCRAPLAB_ECOSYSTEM_SCOPE.md` — the broader media/brand/education/physical-product ecosystem vision
- `SCRAPLAB_BRANDING_SYSTEM.md` / `SCRAPLAB_UI_DESIGN_SYSTEM.md` — visual identity and UI system
- `new_scraplab-design-spec.md`, `SPEC_CONFORMANCE_PLAN.md` — implementation design spec and conformance tracking

## Roadmap

**Near-term (v1.5):** voice material input, mystery challenge mode expansion, random creativity prompts, printable instructions, seasonal challenge packs, a "build with fewer materials" mode.

**Later (v2):** classroom mode, multiple child profiles per household, shared family accounts, shared household inventory, a gallery for uploading finished creations, AI remix mode, educator dashboards.

**Beyond the app:** ScrapLab's long-term thesis is a layered ecosystem — freemium software as the utility engine, creator-led media content as the acquisition engine (YouTube/TikTok/Reels build challenges), and future digital/educational/physical products (printable packs, classroom licenses, branded maker kits) for monetization resilience. See `SCRAPLAB_ECOSYSTEM_SCOPE.md`.

## Non-Goals

ScrapLab is explicitly **not** building, for the current MVP horizon: a social network, a marketplace, AR-guided assembly, an e-commerce craft supply store, or fully unconstrained AI generation of build instructions for children.
