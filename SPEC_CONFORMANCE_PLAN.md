# Product landing pages (DUCT, cider, ScrapLab) + ScrapLab app spec conformance

## Context

Two related pieces of work across four repos.

**Part 1.** `paperweight-systems-web` currently ships exactly one product landing page — `/paperweight` — plus a `/products` index that lists products from the DB. Three other Paperweight Systems products (DUCT, cider, ScrapLab) each have a finished design spec in their own repo but no presence on the company site. This adds a landing page for each at `/products/<slug>`, built to that product's own spec rather than to the PWS house style, and wires them into the product catalog and sitemap.

**Part 2.** While scoping the ScrapLab landing page, an audit of the ScrapLab app itself found it was already largely redesigned to `new_scraplab-design-spec.md` (commit `0a73734`) — but with a set of specific, identifiable deviations still outstanding. This closes those, so the app and its new landing page read as one product.

Source specs:
- `/home/user/DUCT/threshold-design-spec.md` — "Threshold": pure two-tone black/white, Archivo Black, drifting 3D Tetris void, zero border-radius.
- `/home/user/cider/dev-tool-landing-page-design-spec.md` — dark zinc IDE aesthetic, interactive code hero + claim/proof feature rows, rose/amber/emerald accents.
- `/home/user/scraplab/new_scraplab-design-spec.md` — playful blue/lavender, Baloo 2 + Inter, 16–20px radii, pill CTAs. Drives **both** parts.

Decisions confirmed with the user:
- **Visual:** product-native, scoped. Each landing page renders in its own spec's palette/type/radii under a wrapper class; PWS header/footer still wrap it.
- **Content:** DB-driven, same as `/paperweight` — seed content + `/plus` block editing.
- **Wiring:** routes under `products/`, added to the product catalog and `sitemap.ts`. **Not** added to header nav or footer.
- **Deps:** self-host the spec'd fonts (existing `next/font/local` pattern) and add `framer-motion`.
- **ScrapLab app:** full spec conformance sweep (§§2–6).
- **ScrapLab nav:** adopt the spec's vocabulary (Explore → Browse, Library → Build Log) but keep the 5-item bar — do **not** drop `/create` to match §4.6's 4-item count.

Both repos already sit on `claude/product-landing-pages-o2sbfk`, even with `main`.

---

# Part 1 — Landing pages in `paperweight-systems-web`

## Architecture: how "product-native, scoped" works

Follow the existing `.halide-hero` precedent in `src/app/globals.css` — a wrapper class that redefines local CSS custom properties — but keep each product's CSS in its own file next to the page rather than growing `globals.css`:

```
src/app/(site)/products/duct/duct.css         → .duct-page { --duct-black: …; … }
src/app/(site)/products/cider/cider.css       → .cider-page { … }
src/app/(site)/products/scraplab/scraplab.css → .scraplab-page { … }
```

Each `page.tsx` does `import "./<slug>.css"` and renders everything inside `<div className="<slug>-page …">`. Rules:

- Layout/spacing uses stock Tailwind utilities; product colors come from the scoped CSS vars (`bg-[var(--duct-panel)]`) or hand-written classes in the product CSS file.
- **Never** use the PWS theme tokens (`bg-oxide`, `text-muted`, `border-hairline`, `font-display`, `rounded-card`) inside a product page — those are the house style and would break the scoping.
- Three global rules must be overridden inside each wrapper, or PWS bleeds through: `::selection` (globally oxide `#ff3c00`), `:focus-visible { outline: 2px solid var(--pws-accent) }`, and `body`'s oxide radial gradient (cover it with an opaque page background). DUCT in particular is spec'd as "no color anywhere" — an oxide selection highlight would violate §2.
- Do not use `SectionFrame`/`ArchiveRow`/`DisplayHeading`/`AngularButton` from `@/components/pws` on these pages.
- `PwsGlobalTexture` (grain at `z-[70]`, fixed hairline, "SYS / ONLINE" corner label) still overlays all three. That is intended site chrome; it is `aria-hidden` and low-opacity, so it is acceptable on the light ScrapLab page too.

Each page is a Server Component that calls `getPage(slug)` and passes copy down to `"use client"` child components for the interactive parts.

## Fonts

Download latin-subset woff2 from `fonts.gstatic.com` (verified reachable; jsdelivr is blocked by the proxy) into `src/fonts/`, matching the existing naming convention:

| Product | Files |
|---|---|
| DUCT | `archivo-black-latin-400-normal.woff2`, `archivo-latin-{400,500,700}-normal.woff2`, `ibm-plex-mono-latin-{400,500}-normal.woff2` |
| ScrapLab | `baloo2-latin-{600,700}-normal.woff2`, `inter-latin-{400,500,600}-normal.woff2` |
| cider | none — the spec calls for Tailwind's default `font-sans`/`font-mono` stacks |

Add matching `localFont` exports to `src/lib/fonts.ts` (`--font-archivo-black`, `--font-archivo`, `--font-ibm-plex-mono`, `--font-baloo`, `--font-inter`), each `display: "swap"`. Apply the `.variable` classes **on each page's wrapper div, not in `src/app/layout.tsx`** — that keeps the new faces off every other route.

## Files

**New**
- `src/app/(site)/products/duct/page.tsx` + `duct.css` + `DuctVoid.tsx`, `DuctModes.tsx` (client)
- `src/app/(site)/products/cider/page.tsx` + `cider.css` + `CodeHero.tsx`, `FeatureRows.tsx` (client)
- `src/app/(site)/products/scraplab/page.tsx` + `scraplab.css` + `AgeBands.tsx` (client)

**Modified**
- `src/lib/fonts.ts` — five new `localFont` exports
- `src/lib/pageContent.ts` — three new entries in `pageBlockSchemas`
- `src/content/seed.ts` — three new `seedPages` entries + three new `seedProducts` records
- `src/lib/db/seed.ts` — one change, see below
- `src/app/sitemap.ts` — add the three routes to `staticRoutes`
- `src/app/plus/(admin)/pages/page.tsx` — add the three slugs to `PUBLIC_PATHS`
- `package.json` — add `framer-motion`

## Content + catalog wiring

**Page copy** follows the `/paperweight` pattern exactly: a `pageBlockSchemas` entry declares the blocks, `seedPages` holds the default copy, the page reads via `textBlock(page, key)` / `listBlock<T>(page, key)`, and `/plus/pages/<slug>` renders the edit form from the same schema for free. `runSeed` already uses `INSERT OR IGNORE` for pages, so the three new pages appear in an existing production DB on next boot, and `getPage`'s per-key seed fallback means they render even with no DB configured.

**One required fix in `src/lib/db/seed.ts`:** the products branch is gated on `tableEmpty(db, "products")`, so adding rows to `seedProducts` would never reach the live DB. Change that branch to the same per-row `INSERT OR IGNORE` the pages loop already uses (`products.slug` is `UNIQUE`, so it is idempotent and will not clobber copy edited in `/plus`). Do **not** add a `002-` migration for this — a migration that inserts products would run *before* `runSeed` and make `tableEmpty` false, so a fresh database would silently never get the Paperweight row.

**Catalog records** (`seedProducts`), each with `primaryUrl` pointing at its new page:

| slug | status | primaryUrl | featured | sortOrder |
|---|---|---|---|---|
| `duct` | `beta` | `/products/duct` | false | 1 |
| `cider` | `coming-soon` | `/products/cider` | false | 2 |
| `scraplab` | `coming-soon` | `/products/scraplab` | false | 3 |

`/products/page.tsx` and the home page's featured strip need no code changes — they render whatever the catalog returns.

**No product has a deployed URL** (checked all three repos). So every page's CTA href is a `text` block (`ctaUrl`, `ctaSecondaryUrl`), seeded with the GitHub repo URL and changeable in `/plus` once a real URL exists — no hardcoded placeholder to hunt down later.

## Page 1 — `/products/duct`

The DUCT spec describes the *app's control room UI*, not a landing page, so translate its language into marketing sections rather than rebuilding the chat app.

Tokens (`.duct-page`): `--black #000`, `--white #FFF`, `--panel #0D0D0D`, `--panel-2 #141414`, `--line #2B2B2B`, `--grey #8C8C8C`, `--grey-dim #4D4D4D`. `border-radius: 0` on everything. Archivo Black display, Archivo body, IBM Plex Mono for all meta (uppercase, `0.1–0.2em` tracking, 9–11px).

Sections:
1. **Header strip** — wordmark at `clamp(48px, 7vw, 84px)` with trailing dimmed period; right-aligned mono status block with the 2.4s opacity-pulse dot.
2. **Ticker** — repeated uppercase mono string, hairline rule above and below.
3. **Hero** — headline + sub, two CTAs (solid white fill / hairline outline).
4. **Modes** — the spec's jumbo nav blocks (§6) repurposed as DUCT's four modes from its README: Vent `V-01`, Reframe `R-02`, Extract `E-03`, Pressure `P-04`. 4-column grid at `1.6fr 1fr 1fr 1fr` with 2px `--line` gutters; hover → `--panel-2`, active → hard white/black invert.
5. **Thread** — the message-panel treatment (§6) showing a real reflection exchange: system messages `--panel` fill + 3px white left border, user messages transparent + `--line` border, one alert message as full white/black invert. Mono meta row above each body.
6. **Posture / Signal** — the two jumbo-number panels, including the generated on/off `block-viz` bitmap grid.
7. **Footer line** — centered mono, dim, wide tracking, no links.

**The void** (`DuctVoid.tsx`, client): fixed full-viewport `z-0` behind the page. 1px white-on-black 80px grid at `rotateX(78deg)` from `1600px` perspective; 8 extruded slabs each built from 3 CSS faces (top `#e9e9e9`, front `#1c1c1c`, side `#0a0a0a`) at varied x/y/z/`rotateY`; the whole field on one shared 34s ease-in-out drift (±22px bob + slight rotation). Disabled entirely under `prefers-reduced-motion`. Page shell sits at `z-2`.

Copy voice per §9: spatial/passage language (corridor, passage, threshold, relay, signal), plain system statements, no apology.

Blocks: `heroStatus`, `heroTitle`, `heroSub`, `tickerText`, `ctaLabel`, `ctaUrl`, `ctaSecondaryLabel`, `ctaSecondaryUrl`, `modesEyebrow`, `modesHeading`, `modes` (`[{"code","label","body"}]`), `threadHeading`, `thread` (`[{"role":"system|user|alert","meta","body"}]`), `postureLabel`, `postureValue`, `postureBody`, `signalLabel`, `signalValue`, `closingLine`.

## Page 2 — `/products/cider`

The only one of the three that is already a landing-page spec, so follow its structure directly — with the spec's own §6 defects fixed rather than reproduced.

Tokens (`.cider-page`): page `#09090b`, panel `#111115`, panel-deep `#0d0d0f`, panel-hover `#15151a`, zinc-800/700 borders, zinc-400/500/600 text, accents rose `#fb7185`, amber `#fbbf24`, emerald `#34d399`. `rounded-xl` editor, `rounded-2xl` rows, `rounded-full` badge. `::selection` → `rose-500/30` (overrides the site's oxide).

**Section 1 — interactive code hero** (`CodeHero.tsx`, client). Grid `lg:grid-cols-12`, left `col-span-5` / right `col-span-7`. Left: `Terminal`-icon pill badge, H1, supporting paragraph, "Walkthrough" overline, three step buttons. Right: mock editor — header bar with three inert muted-zinc traffic dots, `FileCode2` + filename chip, copy button; body is a line-numbered, syntax-highlighted block.

Use **cider's real code**, not the spec's React sample — `examples/hello-cider/Sources/HelloCider/HelloCiderApp.swift` (`@main struct HelloCiderApp: CiderApp`, `@CiderState private var count`, `VStack` / `Text` / `Button`). Filename `HelloCiderApp.swift`. Walkthrough steps point at the `@CiderState` line, the `Button` action line, and the `Text("Count: \(count)")` line — which is the honest version of the spec's "show, don't tell" intent (§7).

Interaction per §3.3: hovering a step drives `activeLine`, the matching row gets a framer-motion `layoutId="active-line-bg"` bar (`border-l-2` rose, `bg-zinc-800/40`, `-inset-x-4`) that *slides* between lines, and every other line dims to `opacity: 0.3` over 200ms.

**Section 2 — claim & proof** (`FeatureRows.tsx`, client). Three stacked rows, `flex-col md:flex-row`, proof panel `md:w-80` with `border-t` on mobile / `border-l` on desktop. Default state shows three skeleton bars; `group-hover` fades them out while the real proof text fades/slides in. On row hover, a framer-motion band sweeps `top: 0% → 100%` with an opacity pulse `[0, 0.5, 0]` on a 1.5s infinite linear loop.

Features mapped to cider's actual README claims:

| id | Title | Icon | Accent | Proof label / content |
|---|---|---|---|---|
| `linux` | Builds and runs on Linux | `Activity` | emerald | Build Output — `cider doctor` / `cider build` success lines |
| `swift` | Real Swift, not a port | `ShieldCheck` | amber | Editor Diagnostics — SwiftPM/type output |
| `honest` | Loud, useful failures | `Cpu` | rose | Runtime Diagnostic — an unsupported-call diagnostic naming what/where/why/fix |

Copy must respect cider's stated non-goals (README): no iOS emulation, no Xcode replacement, no compatibility claim — and its pre-alpha status.

**Spec defects to fix while building (§6):**
1. Replace the runtime-built `to-${accent}-500/10` gradient class with an explicit static map keyed on a `'emerald' | 'amber' | 'rose'` union — Tailwind's JIT cannot see dynamically constructed names.
2. Wire the copy button to `navigator.clipboard.writeText()` with the real source string.
3. Add `onFocus`/`onBlur` alongside `onMouseEnter`/`onMouseLeave` on the walkthrough buttons so the highlight is keyboard-reachable.
4. `aria-hidden` on all decorative icons.
5. Pair the rose active state with a non-color indicator (the line-number badge already changes shape/weight — make that explicit).
6. Drop `min-h-screen` on both sections — this page has a site header/footer and more content below, so two forced full-viewport blocks are wrong here (§6.6).

Blocks: `heroBadge`, `heroTitle`, `heroSub`, `ctaLabel`, `ctaUrl`, `ctaSecondaryLabel`, `ctaSecondaryUrl`, `walkthroughLabel`, `demoFilename`, `demoCode` (`[{"num","type","text","indent","tokens":[{"text","className"}]}]`), `walkthroughSteps` (`[{"line","text"}]`), `featuresHeading`, `featuresSub`, `features` (`[{"id","title","description","accent","proofLabel","proofLines":[{"text","dim"}]}]`).

Icons can't live in JSON — look them up in the component by `feature.id`, defaulting safely for unknown ids so a bad `/plus` edit can't crash the page. Same for `accent`: validate against the union, fall back to zinc.

## Page 3 — `/products/scraplab`

Another app-UI spec to translate into a landing page. This is the only **light** page on the site. Because Part 2 brings the app itself fully onto this spec, the landing page and the app should be checked against each other at the end.

Tokens (`.scraplab-page`): ScrapLab Blue `#2D3FE0`, Soft Lavender `#EDEBFB`/`#E4E1F9`, Canvas White `#FFF`, Craft Orange `#F4934B`, Sunshine Yellow `#FFC93C`, Leaf `#5FBF7A`, Amber `#F2A93B`, Coral `#E8604C`, Ink `#1C1C28`, Slate `#6B6B7B`, Mist `#F4F4F8`, Line `#E6E6EF`. Cards 16–20px radius, pill buttons, soft-filled chips. Baloo 2 headlines, Inter body, tabular figures on counters.

Honor §2's reservation rule and §6: blue and orange only for hero/CTA moments, everyday sections on lavender/white, red-family colors **only** for safety labels.

Sections:
1. **Hero** — full-bleed ScrapLab Blue with the signature concave curve into the white sheet below; speech-bubble panel carrying the value prop; Craft Orange pill CTA.
2. **Age bands** (`AgeBands.tsx`, client) — the "hand-pick your character" carousel as horizontally scrollable cards: Little Builder 3–5, Junior Maker 6–8, Master Crafter 9–10; active card enlarged on an orange rounded-square. Use the same three bands and copy the app's `/onboarding` already ships, so the two agree.
3. **How it works** — inventory-first, per `SCRAPLAB_PROJECT_SCOPE.md`: materials in → projects out. Reuse the scope doc's own example (cardboard tube, tape, plastic cup, markers → rocket ship, binoculars, mini puppet, marble launcher).
4. **Material picker preview** — filter-pill row + soft-filled material tiles in a grid, selected state = orange border + check badge.
5. **Project cards** — exact card anatomy from §4.4, with the Reality Indicator chip row (time / cleanup / supervision) always visible beneath the description, never collapsed.
6. **Closing CTA** — lavender, single heading + pill button.

Supervision uses the Leaf/Amber/Coral traffic-light coding **plus a text label** in every chip, so the level never depends on color alone.

Blocks: `heroTitle`, `heroSub`, `heroBubble`, `ctaLabel`, `ctaUrl`, `ctaSecondaryLabel`, `ctaSecondaryUrl`, `ageEyebrow`, `ageHeading`, `ageBands` (`[{"name","range","body"}]`), `howHeading`, `howSteps` (`[{"title","body"}]`), `materialsHeading`, `materialsSub`, `materials` (`[{"label"}]`), `projectsHeading`, `projects` (`[{"title","body","age","time","cleanup","supervision":"independent|assist|full"}]`), `closingHeading`, `closingBody`.

---

# Part 2 — ScrapLab app spec conformance (`/home/user/scraplab`)

## What already matches (leave alone)

The `0a73734` redesign landed the foundation: exact spec color values in `src/app/globals.css` (Craft Orange ramp, ScrapLab Blue, Soft Lavender, Ink/Slate/Line, leaf/caution/coral, sunshine), Baloo 2 + Inter, 16/20/28px radii, `shadow-card*`, pill primary buttons, soft-filled chips, `SupervisionBadge` with icon + text label, `MaterialCard`'s orange-border + check-badge selected state, the blue `/onboarding` age bands, the blue `/build/[id]/complete` screen with Sunshine confetti and its concave sheet, and the `/create/manual` search + filter-pill + 4-col grid + sticky CTA bar.

Note the token **names** are legacy (`builder-*`, `kraft-*`, `walnut-*`, `cream-*`) while the values are the spec's. Keep the names — renaming them is a large no-value diff.

## 2A. Palette violations — 57 raw Tailwind color utilities across 16 files

§2 defines the whole palette and rules that the red family is reserved for safety labels and that green (Leaf) means supervision-cleared. The app still uses stock Tailwind `red-*`, `green-*`, `blue-*`, `yellow-*`, `purple-*`, `pink-*` in four distinct roles. Fix each role consistently rather than one-by-one:

| Role | Where | Fix |
|---|---|---|
| **Error / destructive** — `red-50/100/200/500/600/700` (~24 uses) | `auth`, `build/mystery`, `create/scan`, `explore`, `explore/[slug]`, `library`, `profile`, `subscription`, `PlanUsageIndicator`, `Button` (danger variant) | Coral token: `bg-coral/10` panels, `border-coral/30`, `text-coral-text` labels, `bg-coral` solid fills. Alert semantics are a legitimate red-family use; raw Tailwind red is not. |
| **Success / positive** — `green-50/100/500/600/700` (~12 uses) | `create/scan`, `upgrade` (checkmarks) | Leaf token (`bg-leaf/15`, `text-leaf-text`) — these are genuine cleared/success states. |
| **Match-quality chips** — `bg-green-100 text-green-700` | `ProjectCard`, `CreateMethods`, `ChallengesList`, `library`, `explore/[slug]` | **Not** Leaf. §2 reserves green for supervision; using it for "Great Match" makes green mean two things on the same card. Re-color onto Craft Orange (`bg-orange-500/15 text-orange-700`) for the strongest match and lavender (`bg-cream-100 text-walnut-700`) for weaker ones — §2 already assigns orange to "selected / active states". |
| **Decorative category chips** — `blue-100`, `pink-100`, `purple-100`, `yellow-100`, `red-100` | `ActivityCard`, `explore/[slug]` | A rainbow palette with no basis in §2 at all. Define one exported category→token map (lavender, `sunshine/25`, `orange/15`, `builder/15`, `kraft-300`) and use it in both files. |

## 2B. Orange gradient panels

`from-orange-500 to-orange-700` is not in the spec's vocabulary — §2 assigns orange to CTAs and active states, and the spec's full-bleed panels are ScrapLab Blue. Four sites:

- `HeroActionCard` (home) — retired entirely, see 2C.
- `UpgradeCard`, `upgrade/page.tsx`, `subscription/page.tsx` — these are genuine CTA/conversion moments, which §2 does allow blue or orange for. Replace the gradient with a solid ScrapLab Blue panel carrying a Craft Orange pill CTA — the spec's exact hero+CTA pairing (§4.1, §5).
- `BottomNav`'s at-limit bar `from-orange-400 to-red-500` → solid `bg-coral`.

## 2C. Home dashboard rebuild (§4.2)

`src/app/page.tsx` (59 lines) currently renders: greeting, `SignInNudge`, `HeroActionCard` (orange gradient), a 3-card `QuickActions`, a 2-col "Popular Builds" grid, and a weekly-challenge card. §4.2 specifies something different. Rebuild to:

1. **Greeting row** — child/parent avatar, "Hello, [Name]", notification bell.
2. **Progress module** — "This week: N builds completed" + horizontal progress bar toward a weekly goal, on a rounded panel. §4.2 is explicit that this panel is **purple/blue, not orange** — which is what retires `HeroActionCard`. Data from the existing `/api/build-history`.
3. **Icon quick-nav row** — 5 circular icon badges: **Materials · Browse · Build Log · Challenges · Saved** (replaces the current 3 square cards with different labels).
4. **"Suggested For You"** — horizontal scroll of project cards (currently a 2-col grid).
5. **"Continue Building"** — in-progress builds with step progress, from `/api/build-history`.
6. **"Household Staples"** — quick-access material chips; `/create/manual` already fetches `staple_flag` inventory, so reuse that call.

Keep `SignInNudge` where it is. Delete `HeroActionCard.tsx` once nothing imports it.

## 2D. Structural items

- **Nav vocabulary** (§4.6, user's call): in `BottomNav.tsx` and `TopNav.tsx`, relabel Explore → **Browse** and Library → **Build Log**. Labels only — keep all 5 entries and keep the `/explore` and `/library` route paths unchanged. Update the same two labels in the new home quick-nav row.
- **Library tab bar** (§6): `library/page.tsx` puts a 3-tab `Saved / History / Collections` bar directly under the header, which §6 says shouldn't be the first thing there. Move it below the page's primary content header so filters read as secondary.
- **Project card anatomy** (§4.4): `ProjectCard` is missing the one-line description and the `[Start →]` CTA the spec's card diagram calls for. Add both; the Reality Indicator chip row already renders and must stay always-visible.
- **Locked/premium pill** (§4.4): `QuickActions` uses a plain "Plus" text pill; the spec calls for the "Unlock" lock-icon pill pattern. Apply wherever locked content is marked.
- **Tabular figures** (§3): no `tabular-nums` anywhere in the app. Add a `.tabular` utility to `globals.css` and apply it to every counter — streak/build counts, step counters (`ProgressStepper`), material counts, `PlanUsageIndicator`.
- **Concave header curve** (§5): confirmed on `/build/[id]/complete` (`rounded-t-[32px]`). Verify `/auth` and `/onboarding` carry the same treatment and add it where missing.

## 2E. Sweep the remaining screens

With the above done, walk every screen not already named — `create/`, `create/scan`, `create/results`, `build/[id]`, `build/mystery`, `challenges`, `explore`, `explore/[slug]`, `projects/[id]`, `profile`, `subscription`, `upgrade`, `upgrade/success`, `auth` — against §§2–6 and correct: off-palette colors, blue or orange used as everyday chrome, radii outside 16–28px, non-pill primary buttons, outlined instead of soft-filled chips, and any supervision indicator that conveys level by color alone.

---

## Verification

**`paperweight-systems-web`**

```sh
cd /home/user/paperweight-systems-web
npm install          # node_modules is absent; also pulls framer-motion
npm run lint && npm run build && npm run dev
```

No database is configured locally, so `readWithFallback` serves the seed path — which is exactly the path to verify, since it proves the new `seedPages` entries and per-key fallbacks are correct.

- `/products/duct`, `/products/cider`, `/products/scraplab` render end to end.
- `/products` lists five products; the three new rows link to the new pages.
- `/` still renders (only Paperweight is `featured`, so the home strip is unchanged).
- Navigate `/products/duct` → `/paperweight` → `/products/scraplab`: PWS chrome must look identical on all three. If oxide selection/focus colors or PWS fonts show up on a product page, or PWS pages pick up a product color, the scoping leaked.
- Keyboard-tab the cider walkthrough — the line highlight must move on focus, not only on hover.
- DevTools "Emulate `prefers-reduced-motion: reduce`" — the DUCT void must stop drifting.
- Narrow to ~375px: DUCT nav collapses to 2 columns and the main grid to 1 (§8), cider rows stack, ScrapLab carousel scrolls.
- Confirm the new woff2 files are requested **only** on their own routes, not on `/` or `/paperweight`.

**`scraplab`**

```sh
cd /home/user/scraplab
npm install && npm run lint && npm run build && npm run dev
```

- The audit grep must come back clean — this is the objective check on 2A:
  ```sh
  grep -rnE '\b(bg|text|border|from|to|ring)-(red|green|blue|yellow|purple|pink|indigo|teal|emerald|amber|sky|violet|gray|slate|zinc|neutral|stone)-[0-9]{2,3}\b' src --include=*.tsx
  ```
- Walk every route at 375px: `/`, `/onboarding`, `/auth`, `/create`, `/create/manual`, `/create/scan`, `/create/results`, `/build/[id]`, `/build/[id]/complete`, `/build/mystery`, `/library`, `/explore`, `/explore/[slug]`, `/projects/[id]`, `/challenges`, `/profile`, `/subscription`, `/upgrade`.
- Blue appears only on `/auth`, `/onboarding`, `/build/[id]/complete` and the new home progress module + upgrade panels; nowhere as everyday chrome (§6).
- Every supervision indicator still carries its text label, not color alone.
- Counters render with tabular figures (digits don't shift width as values change).
- Side-by-side the finished `/products/scraplab` landing page against the app's home screen — same palette, type, radii, chip treatment.

Then commit and push both repos to `claude/product-landing-pages-o2sbfk`. Keep them as two separate commits (or commit series) — the landing pages and the app sweep are independently reviewable.

---

## Flagged for the user

1. **No illustration assets.** The ScrapLab spec (§5) calls for soft 3D/claymation mascot and material art; the app uses emoji throughout and the landing page has nothing. `scraplab_logo_new.png` is a 2.1 MB PNG — too heavy to drop into `paperweight-systems-web/public/` unoptimized. Plan is a type-and-shape-led hero with geometric material tiles, and leaving the app's emoji in place. Real art can be swapped in later; this is the one part of the spec code can't satisfy.
2. **No live product URLs.** None of the three repos names a deployed URL, so all landing-page CTAs seed to GitHub repo links and are editable at `/plus/pages/<slug>` once real URLs exist.
3. **Statuses are a guess** from each repo's README — DUCT `beta`, cider `coming-soon` (self-described pre-alpha), ScrapLab `coming-soon`. Changeable at `/plus/products`.
4. **ScrapLab home rebuild touches data, not just layout.** §4.2's progress module and "Continue Building" need build-history data. `/api/build-history` exists, but if it returns nothing useful for a signed-out or new user, those modules need an empty state — I'll use the existing `EmptyState` component rather than inventing placeholder numbers.
