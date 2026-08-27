# ScrapLab — Visual Design Spec

Derived from the "Kidtopia" metaverse app and "Robo Learning" education app references. Adapted for ScrapLab's product principles: playful, premium, parent-trustworthy, low-friction, kid-safe. Avoids Pinterest clutter and cheap craft-blog aesthetics.

---

## 1. Design Language Summary

Two reference systems, two roles in ScrapLab:

| Reference | What we borrow | Where it applies in ScrapLab |
|---|---|---|
| Kidtopia (deep blue, 3D character cards) | Onboarding drama, hero character/mascot treatment, bold rounded header curves, coin/currency chip pattern | Onboarding, child profile setup, gamified reward moments |
| Robo Learning (lavender, card-based lesson list) | Everyday app chrome — dashboard cards, progress bars, bottom nav, list-based content browsing | Home dashboard, project library, material picker, build progress |

The onboarding/hero moments get the bold saturated treatment; the daily-use screens get the calmer lavender/neutral treatment. This split keeps the app feeling premium and not overstimulating for repeat parent use, while still feeling delightful for kid-facing moments.

---

## 2. Color System

### Primary Palette
- **ScrapLab Blue** `#2D3FE0` (deep indigo-blue) — hero headers, onboarding backgrounds, primary CTAs. Pulled from Kidtopia's header/hero blue.
- **Soft Lavender** `#EDEBFB` / `#E4E1F9` — everyday screen backgrounds (dashboard, lists). Pulled from Robo Learning.
- **Canvas White** `#FFFFFF` — card surfaces, sheets, modals.

### Accent Palette
- **Craft Orange** `#F4934B` — primary action accent (replaces Kidtopia's orange character-card accent). Use for "Start Build," selected material chips, active states.
- **Sunshine Yellow** `#FFC93C` — currency/reward chip equivalent → repurposed as **streak/points chip** ("12 builds completed") or badge highlights.
- **Leaf Green** `#5FBF7A` — safety/supervision-cleared indicators ("Independent," "Toddler Safe").
- **Caution Amber** `#F2A93B` — "Adult assist needed" indicator.
- **Alert Coral** `#E8604C` — "Full supervision required" indicator (reserve red-family only for safety labels, never decorative).

### Neutrals
- Ink `#1C1C28` — primary text
- Slate `#6B6B7B` — secondary/body text
- Mist `#F4F4F8` — input field fills, disabled states
- Line `#E6E6EF` — dividers, card borders

**Rule:** Deep blue and orange are reserved for hero/onboarding/CTA moments only — never as a body-text background — to avoid visual fatigue for parents scanning quickly.

---

## 3. Typography

- **Display/Headlines:** Rounded-friendly sans-serif with high x-height (e.g., Baloo 2, Fredoka, or Nunito Bold) — matches the soft, playful headline weight seen in "Hand-pick Your Character" and "Let's Start Your Learning Adventure."
  - H1: 28–32px, bold, tight leading — used for screen titles ("Pick a New Build")
  - H2: 20–22px, semibold — card group headers ("Popular Projects," "Lessons")
- **Body:** Neutral grotesk (Inter or similar) for legibility at small sizes — material lists, instructions, descriptions.
  - Body: 14–15px regular, Slate color
  - Caption/meta: 12–13px, used for time/cleanup/supervision tags
- **Numerals:** Tabular figures for counters (streaks, item counts) — matches the coin-counter treatment (e.g., "3,100").

---

## 4. Layout Patterns (mapped to ScrapLab screens)

### 4.1 Onboarding / Hero Screens
Reference: Kidtopia's full-bleed blue hero with character illustration + rounded speech-bubble CTA panel; Robo Learning's stacked-books hero.

**Applied to ScrapLab:**
- **Welcome screen:** Full-bleed ScrapLab Blue background, centered 3D-style hero illustration (a friendly "scrap mascot" — e.g., a cardboard-robot character built from craft materials) with a soft speech-bubble panel below stating the value prop ("Turn your junk drawer into your kid's next big build!"). Circular arrow/next button, bottom-center.
- **Child profile setup:** Reuse the Kidtopia "hand-pick your character" card carousel pattern — horizontally scrollable age-avatar cards (not literal game avatars, but friendly age-band mascots: "Little Builder 3–5," "Junior Maker 6–8," "Master Crafter 9–10") with the active card enlarged on an orange rounded-square background.

### 4.2 Home Dashboard
Reference: Robo Learning's "Hello, Marion / Progress 10%" screen with level bar + icon row + card list.

**Applied to ScrapLab:**
- Top greeting row: parent/child avatar, "Hello, [Name]," small supervision/notification bell icon.
- Progress module (Kidtopia-style rounded panel, but purple/blue not orange): "This week: 3 builds completed" with a horizontal progress bar toward a soft goal (e.g., weekly streak).
- Icon quick-nav row (5 icons, circular badges): **Materials · Browse · Build Log · Challenges · Saved** — direct parallel to the Lessons/Games/Stories/Activities/Discover row.
- Below: stacked content cards —
  - "Suggested For You" (horizontal scroll of project cards, mirrors "Circus Carnival Fun" card)
  - "Continue Building" (in-progress builds with step progress)
  - "Household Staples" (quick-access material chips)

### 4.3 Material Input / Picker
No direct reference equivalent — extend the Robo Learning search-bar + filter-pill pattern from "Pick a New Learning Lesson."

- Search bar with icon + filter/sort control (rounded pill, top right — same shape as the sliders icon in reference 3).
- Filter pills row: "All · Recently Used · Household Staples · By Category."
- Material grid: square icon tiles (illustrated material icons — cardboard tube, tape, cup, etc.) in a 4-column grid, selectable state = orange border + check badge (mirrors the "Explore" character-select treatment, simplified to a grid).
- Sticky bottom bar: "X materials selected → Find Projects" primary CTA in Craft Orange.

### 4.4 Project / Recommendation Cards
Reference: "Circus Carnival Fun" card (image, title, rating, price chip, CTA button) and the "Lesson One" progress cards.

**Applied to ScrapLab card anatomy:**
```
┌─────────────────────────────┐
│ [Project photo/illustration] │
│                               │
│ Title                 ⭐ Age  │
│ One-line description...      │
│                               │
│ ⏱ 15 min   🧹 Low mess  🧑 Check-in │
│                    [Start →] │
└─────────────────────────────┘
```
- Reality Indicators (time / cleanup / supervision) render as a compact icon-chip row directly beneath the description — always visible, never hidden behind a tap, per the product's "highly visible, not buried in small print" requirement.
- Supervision level uses the Leaf/Amber/Coral traffic-light coding from Section 2.
- Locked/premium projects reuse the "Unlock" lock-icon pill pattern from "Lesson Two" (Robo Learning).

### 4.5 Guided Build (Step Mode)
Reference: Lesson progress cards with "0/5," "0/6" completion counters.

- Step counter badge top-right of the header, same rounded-pill shape as "0/5": "Step 2/6."
- Large step illustration/photo area.
- Bottom nav bar: Back / Mark Done / Next — same weight and placement as Robo Learning's bottom icon dock, but text-labeled buttons instead of icons only (parents need clarity, not iconography guessing).
- Completed build state: confetti/badge moment using Sunshine Yellow, echoing the coin-reward feeling from Kidtopia without implying in-app currency (ScrapLab has no monetized currency system — this is a pure celebration state, not a spendable token).

### 4.6 Bottom Navigation
Reference: Kidtopia's pill-shaped floating bottom bar (home / controller / ticket / settings icons on blue).

**Applied to ScrapLab:** Floating rounded bottom bar, Canvas White on Soft Lavender screens (not blue — reserve blue chrome for onboarding only), 4 icons: **Home · Browse · Build Log · Profile.** Active icon gets a filled Craft Orange circular background, matching the reference's active-state treatment.

---

## 5. Component Notes

- **Cards:** 16–20px corner radius throughout (matches the soft rounded corners in both references — no sharp edges anywhere in the system).
- **Buttons:** Fully rounded (pill) primary buttons, solid Craft Orange fill, white bold label — direct match to "Join Now" / "Start Learning" button style.
- **Chips/badges:** Fully rounded, soft-filled background (not outlined) — matches the coin chip and rating chip treatment.
- **Header curve:** For hero/onboarding screens only, the header uses a soft concave curve transitioning into the white content sheet below (signature shape from both Kidtopia screens) — gives the "premium app," not "craft blog," feel the scope calls for.
- **Illustration style:** Soft 3D-rendered / claymation-style character and object illustrations (not flat vector, not stock photography) for mascots and empty states — consistent with both references' 3D character art. Real photos are used only for user-uploaded material photos and finished-build photos, never for iconography.

---

## 6. What NOT to carry over

- No literal in-app currency/coin economy — ScrapLab is not gamified with spendable points; keep "streaks/badges" purely celebratory, not transactional (avoids scope creep into the metaverse-avatar shopping pattern).
- No dense multi-tab category bars competing for space at the very top (reference 3's "All / Beginners / Intermediate / Advanced" pill row is fine as a secondary filter, but shouldn't be the first thing under the header — Reality Indicators and material match take priority for parents scanning fast).
- Avoid the deep-blue chrome bleeding into everyday utility screens (material picker, build log) — reserve it for emotionally high moments (welcome, milestone/completion) so the app doesn't feel visually loud for repeat daily use.
