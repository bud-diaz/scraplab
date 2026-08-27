# ScrapLab

**Turn household clutter into kid-friendly creativity — in under 60 seconds.**

ScrapLab is a web app that helps parents and caregivers figure out what to build with the random household materials kids already have lying around — cardboard tubes, bottle caps, egg cartons, tape, string — instead of buying another craft kit. Tell ScrapLab what you have (or snap a photo), and it recommends safe, age-appropriate build projects and open-ended activities with step-by-step instructions.

---

## The problem

Kids collect materials for imaginary future projects. Parents are left holding the clutter, without the time, budget, or Pinterest-scrolling patience to figure out what to actually make. ScrapLab flips the usual craft-discovery model: instead of starting from a tutorial and a shopping list, it starts from **what you already have**.

## Core product principles

- **Inventory-first** — recommendations are driven by the materials on hand, not a fixed content library you have to search through.
- **Safety by design** — every project and activity is age-filtered, with explicit supervision levels and safety notes; no fire, sharps, or chemicals surfaced to age groups they aren't appropriate for.
- **Fast, low-friction UX** — tap-to-select materials or upload a photo; no lengthy forms.
- **Kid delight** — playful project names, challenge modes, and a sense of accomplishment on completion.

## How it works

1. **Tell ScrapLab what you have.** Pick materials from a categorized library, or upload a photo and let AI vision detect them (Google Gemini). Detected items always require user confirmation before they're used — vision is a starting point, not a guarantee.
2. **Get ranked project recommendations.** A deterministic matching engine scores projects/activities against your material list, factoring in the child's age, safety constraints, and stated preferences (time, mess tolerance, supervision level).
3. **No dead ends.** If you're missing a material, ScrapLab looks for a curated substitution (e.g. googly eyes → drawn eyes) before falling back to simplified or "close match" alternatives — you always get *something* usable, ranked exact → close → fallback.
4. **Build it.** Follow step-by-step instructions with safety call-outs, mark progress, and complete the build.
5. **Save and revisit.** Bookmark favorites and look back at build history and completed projects over time.

## Feature overview

| Area | What it does |
|---|---|
| **Material input** | Manual material picker (browse/search a categorized library) and photo-based material recognition with confirm/edit before use |
| **Recommendation engine** | Hybrid deterministic scoring engine — exact/close/fallback matching, material substitution support, age & safety gating |
| **Project reality indicators** | Time estimate, cleanup level, and supervision level surfaced up front on every project so parents can gauge effort before starting |
| **Guided build experience** | Step-by-step instructions with progress tracking, save-for-later, and build history |
| **Activities library** | A separate library of open-ended activities (cooperative, science, engineering, storytelling, pretend-play, seasonal, puzzle, art) tagged by energy level, attention span, and environment, with AI-assisted suggestion copy |
| **Challenges** | Themed/curated challenge builds, including a "mystery materials" build mode |
| **Household inventory & profiles** | Remembers household "staple" materials and supports multiple child profiles with age-based personalization |
| **Freemium access control** | Free tier: limited daily recommendations, manual material input, one child profile. Plus tier: unlimited recommendations, photo material recognition, unlimited saved projects, and up to 10 child profiles |
| **Billing** | Stripe-powered subscription checkout, billing portal, and webhook-driven plan sync |

## Safety model

Recommendations are hard-gated by age appropriateness and supervision requirements. Hard restrictions apply across the board: no fire, knives, electrical work, toxic substances, or unsupervised hazardous builds. Every project carries a supervision label (independent / check-in / adult assist / full supervision) and explicit safety notes, and AI is only used for secondary enhancements (naming, encouragement copy, variations) — never for unconstrained project generation for young children.

## Who it's for

- **Primary:** parents/caregivers of kids ages 3–10 — busy parents, budget-conscious and apartment-living families, rainy-day activity seekers, and anyone encouraging screen-light creative play.
- **Secondary:** educators — teachers, daycare providers, homeschool families, and after-school programs.

## Tech stack

- **Frontend:** Next.js 16 (App Router), React 19, TypeScript, Tailwind CSS 4
- **Backend:** Next.js API routes
- **Database & storage:** Supabase (Postgres + Storage)
- **AI:** Google Gemini (`@google/genai`) for photo-based material detection and AI-assisted activity suggestion copy
- **Payments:** Stripe (subscription checkout, billing portal, webhooks)
- **Validation:** Zod

## Project structure

```
src/app/            Routes — onboarding, create flow (manual/scan/results), build flow,
                     explore/library/challenges, subscription & upgrade, API routes
src/components/      UI components (cards, layout, form/input primitives)
src/lib/
  ai/                Vision-based material detection, AI-assisted suggestion copy
  recommendations/   Deterministic recommendation/matching engine
  safety/            Age-appropriateness and safety gating
  access/            Plan limits (free vs. Plus) and entitlement checks
  db/                Supabase client + auth helpers
supabase/
  migrations/        Database schema migrations
  seed.sql           Seed data
scraplab_activities_001_100.json   Bulk activity content matching the activity schema
scraplab_activity_schema.json      JSON schema for activity content
```

## Getting started

### Prerequisites

- Node.js and npm
- A [Supabase](https://supabase.com) project
- A [Google AI Studio](https://aistudio.google.com/apikey) API key (for photo material detection)
- A [Stripe](https://dashboard.stripe.com) account (for subscription billing)

### Setup

```bash
npm install
cp .env.example .env.local   # fill in Supabase, Google AI, and Stripe credentials
```

Apply the database schema by running the SQL files in `supabase/migrations/` (in order) against your Supabase project, then optionally load `supabase/seed.sql` for sample data.

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start the local dev server |
| `npm run build` | Production build |
| `npm run start` | Start the production server |
| `npm run lint` | Run ESLint |

## Business model

ScrapLab is freemium. The free tier is a genuinely useful daily-driver (limited daily recommendations, manual material input, one child profile); **ScrapLab Plus** unlocks unlimited recommendations, AI photo material recognition, unlimited saved projects, multiple child profiles, and premium challenge content. See `SCRAPLAB_PROJECT_SCOPE.md` for full pricing and monetization details.

## Further documentation

This repo includes deeper planning documents for context on product direction and design:

- [`SCRAPLAB_PROJECT_SCOPE.md`](./SCRAPLAB_PROJECT_SCOPE.md) — full product scope, MVP definition, data model, and business model
- [`SCRAPLAB_ECOSYSTEM_SCOPE.md`](./SCRAPLAB_ECOSYSTEM_SCOPE.md) — the broader brand/media/product ecosystem strategy
- [`SCRAPLAB_UI_DESIGN_SYSTEM.md`](./SCRAPLAB_UI_DESIGN_SYSTEM.md) — UI design system and component conventions
- [`SCRAPLAB_BRANDING_SYSTEM.md`](./SCRAPLAB_BRANDING_SYSTEM.md) — brand identity and voice
- [`new_scraplab-design-spec.md`](./new_scraplab-design-spec.md) — design spec

## Non-goals (current scope)

ScrapLab is intentionally not building, for now: a social network, a marketplace, AR-guided assembly, educator analytics, unrestricted AI craft generation, or an e-commerce craft supply store.
