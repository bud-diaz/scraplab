# Native iOS Rewrite Status

Tracking file for work against [`NATIVE_IOS_REWRITE_PLAN.md`](./NATIVE_IOS_REWRITE_PLAN.md). Update this between commits and phase boundaries so the repo shows what is done, what is still Linux-verifiable, and what is blocked on macOS/Xcode.

_Last updated: 2026-09-13 (continued session) on `feat/native-ios-foundation`._

## 2026-09-13 Profile and billing — Phase 6 SwiftUI slice

Same research-before-writing approach as Phases 4 and 5: had an Explore agent read
`src/app/profile/page.tsx` and its sub-components, `src/app/subscription/page.tsx`,
`src/lib/native/purchases.ts`, `src/app/build/mystery/page.tsx`, `src/app/challenges/page.tsx`,
and the delete-account/child-profiles/household-inventory route handlers directly, rather
than working from the plan doc's one-paragraph summary. Two real findings shaped this
slice:

- **RevenueCat cannot be wired for real from this environment.** Adding the `RevenueCat`
  SPM package needs Xcode-driven network dependency resolution this sandbox doesn't have,
  the SDK is Apple-platform-only so it can't join the Linux-testable `ScrapLabCore`
  package, and using it for anything real needs an App Store Connect subscription product
  plus a RevenueCat dashboard entitlement — none of which exist yet. Built the same kind
  of boundary Phase 1 used for the still-unconfigured Supabase auth adapter:
  `PurchaseServicing` protocol + `UnconfiguredPurchaseService`, with `SubscriptionStore`
  written and structured against that protocol so swapping in the real SDK later is a
  one-file change with no call-site edits. Also wired the plan's explicit RevenueCat
  identity-bug fix at the call-site level — `ScrapLabApp` now calls
  `purchaseService.configure(appUserID:)` on every sign-in and `.logOut()` on every
  sign-out — even though the underlying implementation is a documented no-op today.
- **"Challenges" has no backend on the web either** — it's a hardcoded 4-item array there
  too, and only "Mystery Build" and "Minimal Materials Mode" actually link anywhere. Ported
  that honestly (a static list with two live entries and two "Coming Soon" locks) instead
  of inventing a challenges API that doesn't exist on either platform.

Also ported the real `src/app/privacy/page.tsx` copy verbatim into a static
`PrivacyPolicyView` — this is legal text, not something to paraphrase or summarize.

Pure logic: nothing new needed in `ScrapLabCore` beyond one response type
(`SyncRevenueCatResponse`) — `OnboardingChildProfileBuilder` (child-age validation),
`CreateAge.pickerRange` (mystery build's age control), and `EntitlementFeature.householdStaples`/`.mysteryBuild`
already existed from earlier Linux-safe slices and covered everything this phase needed.
That's the earlier groundwork paying off rather than a gap.

SwiftUI screens added under `ios-native/App/Features/Profile/` (macOS/Xcode-unverified):

- `ProfileView`: header (email, plan badge linking to Subscription), Kids CRUD, a Plus-gated Staples section (free users see an `UpgradeCard` instead, matching the web exactly), nav links to Subscription/Challenges/Privacy Policy, delete account, sign out.
- `ChildProfilesStore` + `KidsSectionView` (+ inline `ChildProfileFormView` sheet for add/edit/remove): reuses the existing `OnboardingChildProfileBuilder` for validation instead of duplicating it, surfaces the 429 child-profile-limit response distinctly from a generic failure.
- `HouseholdStaplesStore` + `StaplesSectionView`: toggling a staple re-POSTs the upsert endpoint with the flipped flag rather than tracking the inventory row's own id, matching `StaplesSection` exactly; an "Add Staple" sheet lists materials not yet tracked.
- `DeleteAccountSectionView`: inline confirm-in-place (no modal, no typed confirmation), an Apple-specific cancellation note for Plus users since native never touches Stripe, calls `session.signOut()` on success rather than any extra route (the guest nudges across every tab already react to that automatically).
- `SubscriptionStore` + `SubscriptionView`: free-vs-Plus states, feature list, purchase/restore/manage actions all routed through `PurchaseServicing`, followed by `POST /api/me/sync-revenuecat` (which never trusts the client's purchase result — always re-verifies against RevenueCat server-side). Also now backs the `.upgrade` sheet that several existing `UpgradeCard` buttons already opened.
- `MysteryBuildStore` + `MysteryBuildView`: `GET /api/mystery-materials`, re-roll, an age stepper, "Find Builds" — reuses `CreateRoute.results` exactly like the manual picker and scan flow do.
- `ChallengesView`, `PrivacyPolicyView`: static, as described above.
- Real bug avoided by checking early (same class as Phases 4–5's cross-tab-path bugs): an early draft of `MysteryBuildView`'s "Find Builds" button used `NavigationLink(value: CreateRoute...)` inside Profile's own `[ProfileRoute]`-typed stack, which would have silently done nothing. Fixed by using a plain `Button` that switches tabs and replaces `createPath` directly, matching the pattern `RootTabView.startBuild` already established.
- Redefined `ProfileRoute` from an unused placeholder (`.settings`) to real cases (`.subscription`, `.mysteryBuild`, `.challenges`, `.privacyPolicy`) and wired all four into `RootTabView`'s Profile tab, replacing its last placeholder. Every tab in the app now shows real content — Phases 1–6 of the plan are code-complete pending macOS verification.

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 71 Swift tests (up from 70) |
| `swift -frontend -parse` over every file in `ios-native/App` (69 files, up from 56) | Passed — syntax only |
| `NODE_ENV=test npm test` | Passed: 17 files / 161 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `git diff --check` | Passed |
| Manual grep guard: no `checkout`/`billing/portal` references, no obvious secrets, no `fatalError`/`try!` in `ios-native/App` | Passed |

**Mac-side work required, in addition to the Phase 3/4/5 lists above:**

1. Everything below the standing "Linux can't type-check SwiftUI" caveat applies here too — 13 new App-target files, none compiled yet.
2. **Wiring real billing is its own project, not a checkbox**: create the RevenueCat account and dashboard entitlement, create the auto-renewable subscription product in App Store Connect, add the `RevenueCat` SPM package to `project.yml`, implement a real `PurchaseServicing` adapter around `Purchases.shared`, and test at least one purchase and one restore in the StoreKit sandbox before this phase is actually demoable — none of that can start until this branch is on a Mac with an Apple Developer account attached.
3. Confirm the Kids CRUD age `Picker` with `.pickerStyle(.wheel)` inside a `Form` renders sanely (wheel pickers inside forms can look cramped) and that the inline "Remove {name}? Yes/No" confirmation reads clearly at real size.
4. Confirm `DeleteAccountSectionView`'s flow end to end on a real (test) account: delete, confirm `session.signOut()` fires, confirm every tab reactively falls back to its guest state without a relaunch.
5. Confirm `PrivacyPolicyView`'s Markdown-via-`LocalizedStringKey` bold rendering actually renders `**text**` as bold rather than showing literal asterisks — this is the one place this session used that technique instead of a plain `Text`.

## 2026-09-13 Build and library — Phase 5 SwiftUI slice

Before writing any UI, had an Explore agent read the actual web pages
(`src/app/build/[id]/page.tsx`, `.../complete/page.tsx`, `src/app/library/page.tsx`,
`src/app/page.tsx`, `src/components/ui/StepIllustration.tsx`) rather than working from the
plan doc's summary, because this phase has more state-machine subtlety than Browse or
Create did. That surfaced one fact that would have produced a wrong data model if
guessed: **`/build/[id]`'s `id` is a *project* id/slug, not a build-history row id** — the
build_history row is a separate id (`start_or_resume_build`, called lazily) that the
player only learns about after loading the project. `BuildLogRoute.build(UUID)` and the
existing `.build(id:)` deep-link case both already carried a project id under that same
assumption, so no router changes were needed there, but `BuildPlayerStore` had to be built
around "load a project, then separately start-or-resume a build" rather than "load a
build."

Same standing caveat as Phases 3 and 4, more so here: this phase adds a hand-rolled
`Canvas`-based illustration renderer with zero source SVGs to trace (no visual reference
exists for these, on Linux or otherwise), so the ten step illustrations are a first-pass
approximation of the web's shapes, not a pixel port — expect them to need a real look and
adjustment once they can actually render on a screen.

Pure logic added to `ScrapLabCore` (Linux-tested):

- `BuildFlowLogic.swift`: `BuildStepPlayerState` (clamped step index, `advance()`/`retreat()`, rounded progress percent — mirrors the web's resume-clamp and `Math.round` behavior exactly), `WeeklyProgressSummary` (completed-in-trailing-7-days count against a fixed goal of 5, with the web's four-branch footer message ported verbatim), `ContinueBuildingSelector` and `HouseholdStaplesSelector` (the Home row filters/caps), `BuildHistoryStatusBadge` (Library's status pill text).

SwiftUI screens added (macOS/Xcode-unverified, per the standing Linux-can't-type-check-SwiftUI caveat):

- **Build** (`Features/Build/`): `BuildPlayerStore` + `BuildPlayerView` (loads the project, starts/resumes a build_history row only when signed in, fire-and-forget PATCH on every step change matching the web exactly, an *awaited* PATCH on Complete so a failure can show an inline retry message instead of navigating away), `StepIllustrationView` (ten `Canvas`-drawn shapes, `accessibilityHidden` and gated on `accessibilityReduceMotion` — both are native-only additions the web lacks), `BuildCompleteStore` + `BuildCompleteView` (static celebratory dots instead of a particle library, since the web has no animation here either; Save-to-Library with 409-as-success handling).
- **Library** (`Features/Library/`): `LibraryStore` (parallel-fetches saved projects and build history, a fetch failure is a distinct retry state from "empty"), `LibraryView` (Saved/History/Collections tabs — Collections is a permanent stub matching the web), `SavedProjectCardView`, `BuildHistoryRowView` (deliberately **not tappable**, matching the web's history rows having no `onClick`/`Link`).
- **Home** (`Features/Home/`): `HomeStore` assembling every section, `HomeView` replacing the Phase 1 placeholder content, `GreetingRowView`, `WeeklyProgressView`, `QuickNavRowView`, `SuggestedForYouView`, `ContinueBuildingView`, `HouseholdStaplesView`. Per the plan's own risk note, **`SuggestedForYouView` calls `GET /api/activities?featured=true&limit=10` instead of porting `src/lib/mock-data.ts`** — the mock data is content debt the plan explicitly says not to carry over, and the route already supports `featured` with zero server changes needed.
- Real bug avoided by checking early: naively wiring "tap a saved project" or "start a build" as an in-stack push would have hit the same homogeneous-route-array problem Phase 4 found (`browsePath`/`buildLogPath`/`createPath` are each their own concrete-typed array, not a type-erased `NavigationPath`). Resolved by giving `ProjectDetailView` an `onStartBuild: (UUID) -> Void` closure that `RootTabView` wires to the same tab-switch-and-push the `scraplab://build/<uuid>` deep link already used (`selectedTab = .buildLog; buildLogPath = [.build(id)]`), so Browse, Library, and Home all reach the build player identically without needing a shared route type.
- Extended `BuildLogRoute` with `.complete(projectId: UUID)`, wired all three `BuildLogRoute` cases (`project`/`build`/`complete`) to real screens, wired `Features/Home` into the Home tab and `Features/Library` into the Build Log tab, replacing both remaining placeholders. Every tab now shows real content — the five-tab shell has no `PlaceholderDestination` left except `Create/Profile` settings and Build/Create sub-flows not yet built (multipart create already done in Phase 4; Profile is Phase 6).
- Found and fixed a nested-interactive-control bug in review before it shipped: an early draft of `SavedProjectCardView` put an "unsave" `Button` inside a `NavigationLink`'s label — the two controls fight for the tap gesture in SwiftUI. Fixed by making the card purely presentational and layering the unsave button as a sibling in a `ZStack` at the call site instead.

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 70 Swift tests (up from 62) |
| `swift -frontend -parse` over every file in `ios-native/App` (56 files, up from 39) | Passed — syntax only, does **not** type-check the new `Canvas`/Observation/generic-`DetailPhase` usage |
| `NODE_ENV=test npm test` | Passed: 17 files / 161 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `git diff --check` | Passed |
| Manual grep guard: no `checkout`/`billing/portal` references, no obvious secrets, no `fatalError`/`try!` in `ios-native/App` | Passed |

**Mac-side work required, in addition to the Phase 3/4 lists above:** this is the largest
single batch of new App-target files yet (17 new Swift files under `Features/Build`,
`Features/Library`, `Features/Home`), so expect the highest chance yet of a real compile
error on first `xcodebuild build`. Specific things to check once it builds: (1) the ten
`StepIllustrationView` shapes actually look like their described action rather than
abstract blobs — this is a pure design judgment call with no way to verify without a
screen; (2) the build player's fire-and-forget step PATCH doesn't race the awaited
Complete PATCH if a user taps Next then Complete rapidly; (3) `BuildCompleteView`'s
`.navigationBarBackButtonHidden(true)` actually prevents backing into a finished build;
(4) the full loop end to end on a signed-in account: start a build from a project, advance
through steps, complete it, confirm it appears in Library's History tab as "Done" and
Home's Weekly Progress increments; (5) confirm a paused (abandoned) build shows "Stopped"
in History and does **not** appear in Home's Continue Building row.

## 2026-09-13 Create flow — Phase 4 SwiftUI slice

Ported the whole Create flow described in the plan (`/create`, `/create/manual`,
`/create/results`, `/create/scan`) directly against the live route handlers rather than
the plan doc's summary, to catch shape mismatches early. Same caveat as the Browse slice
above applies with more force here: this phase touches `PhotosPicker`, `UIImagePickerController`,
and `UIImage` JPEG encoding, none of which exist on Linux even as stubs — the syntax-only
parse check cannot catch a wrong argument label, a missing import, or a UIKit API used
incorrectly, only gross grammar errors. Treat every file under `Features/Create/` as
unverified until it has compiled once in Xcode.

Read the actual route handlers rather than trusting the plan summary, and found real
shape details that would have caused silent bugs if guessed:

- `POST /api/activity-recommendations` allows **guests** (identity falls back to a hashed
  IP via `getGuestIdentity`) — only `POST /api/recommendations` (the project-based,
  currently-unused route) requires auth. `CreateResultsStore` attaches a bearer token when
  one exists but never blocks on `session.isAuthenticated`, matching the route.
- `POST /api/scan-materials` requires **both** auth and a Plus entitlement
  (`requireAuth` + `canUsePhotoScan`), so `ScanView` gates on `session.isAuthenticated`
  before ever showing the picker, matching the web page's own `if (!session) return <UpgradeCard>`.
- `GET /api/materials` only supports a server-side `category` filter — there is no search
  param. The manual picker loads the catalog once and does search/category filtering
  entirely client-side (`MaterialCatalogFilter`), matching what the web client already does.
- The web manual picker's age control only offers 3–12 in its dropdown even though the
  backend accepts up to 18, and the scan flow hardcodes age 7 with no picker at all.
  Ported both restrictions as-is (`CreateAge.pickerRange`, `CreateAge.scanDefault`) instead
  of "fixing" a limitation that isn't mine to redesign in this pass.
- **Real navigation bug caught before it shipped:** the web's results-page `ActivityCard`
  links to `/explore/<slug>`, and naively porting that would have pushed a `BrowseRoute`
  value onto `router.createPath` — but `createPath` is a homogeneous `[CreateRoute]` array
  (same pattern as every other tab), so a `BrowseRoute` value has no matching
  `navigationDestination` in that stack and the tap would have silently done nothing.
  Added `CreateRoute.activity(slug:)` instead, so the Create tab pushes its own activity
  detail destination without ever needing a cross-tab route type.

Pure logic added to `ScrapLabCore` (Linux-tested):

- `CreateFlowLogic.swift`: `CreateAge` (backend clamp + web's UI ranges), `MaterialCatalogFilter` (search/category filtering + category derivation), `MaterialSelectionState` (toggle/remove, the backend's 50-material cap, and a deterministic dedupe key mirroring the web's retry-safe `requestId`), `CreateResultsFilter` (the results page's All/Quick/Easy/Family chips, ported as pure predicates over `ActivityMatch`).

SwiftUI screens added under `ios-native/App/Features/Create/` (macOS/Xcode-unverified):

- `CreateMethodListView`: ports `CreateMethods.tsx`'s four method rows (two of which route to the manual picker on the web too — not a native simplification).
- `ManualMaterialPickerStore` + `ManualMaterialPickerView` + `MaterialTileView`: loads the full material catalog once, category chips + search + selection tray + a 4-per-row-equivalent adaptive grid, sticky bottom bar with an age stepper and a "Find Builds" `NavigationLink`.
- `CreateResultsStore` + `CreateResultsView` + `AiSuggestionCardView`: calls `POST /api/activity-recommendations`, renders matches (reusing `ActivityCardView` with its new optional `matchLabel`) and Gemini `AiSuggestion` cards with expandable steps, handles the 429 daily-limit and 403 plan-gate states distinctly from a generic network failure.
- `ScanStore` + `ScanView` + `CameraCapture` + `PhotoUploadPreparer`: `PhotosPicker` and a thin `UIImagePickerController` wrapper for camera capture (`PhotosPicker` cannot trigger the camera), `PhotoUploadPreparer` applies the existing `PhotoCapturePolicy` numbers with real `UIGraphicsImageRenderer`/`UIImage.jpegData` calls, multipart upload via the existing `MultipartFormData` builder, sign-in nudge for guests, upgrade card for the plan gate.
- Extended `CreateRoute` with `.results(materialIDs:childAge:)` and `.activity(slug:)`; wired all four Create screens into `RootTabView`'s Create tab, replacing its placeholder.
- `ActivityCardView` gained an optional `matchLabel: String?` (defaults `nil`, so the existing Browse-tab call site is unaffected) to show the recommendation match badge as an extra `MetadataChip` instead of an overlay badge, which keeps the layout change low-risk without a device to check it on.

Deliberately deferred: no pre-selection of household staples for Plus users in the manual picker (the web does this via an extra `/api/household-inventory` call; noted as a gap, not silently dropped), no drag-and-drop equivalent for the scan upload area (mobile doesn't have a drag-and-drop gesture to port), no offline queueing for a scan/recommendation request made while offline.

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 62 Swift tests (up from 55) |
| `swift -frontend -parse` over every file in `ios-native/App` (39 files, up from 28) | Passed — syntax only, does **not** type-check SwiftUI/UIKit/PhotosUI/Observation usage |
| `NODE_ENV=test npm test` | Passed: 17 files / 161 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `git diff --check` | Passed |
| Manual grep guard: no `checkout`/`billing/portal` references, no obvious secrets, no `fatalError`/`try!` in `ios-native/App` | Passed |

**Mac-side work required, in addition to the Phase 3 list above:** `PhotosPicker`,
`UIImagePickerController`, and `UIGraphicsImageRenderer`/`UIImage.jpegData` in
`PhotoUploadPreparer`/`CameraCapture`/`ScanStore` are the highest-risk new surface —
verify camera permission prompts actually fire (`NSCameraUsageDescription`/
`NSPhotoLibraryUsageDescription` already exist in `Info.plist` from Phase 1, but this is
the first code that actually exercises them), verify a real photo survives resize +
upload without tripping the backend's 413/415, and confirm `CameraCapture`'s
`@Environment(\.dismiss)` actually dismisses the `fullScreenCover` from inside the
`UIImagePickerControllerDelegate` callback. Also confirm the full loop end to end: manual
pick → results → tap a card → activity detail, and scan → detected list → results, on a
signed-in Plus account (for scan) and a signed-out/free account (for the plan-gate and
sign-in-nudge paths).

## 2026-09-13 Browse/detail screens — first Phase 3 SwiftUI slice

Picked up directly from the query/capture groundwork below (which was already sitting
uncommitted in the worktree) and used it to build the first real screens beyond the
Phase 1 foundation. This is the first slice with actual `Features/Browse` SwiftUI code
instead of `PlaceholderDestination`, so treat it as higher-risk than the pure-package
work until it has run through Xcode: **Linux cannot type-check SwiftUI at all** — the
`swift -frontend -parse` check below only proves the files are syntactically valid
Swift, not that they compile against the real SDK. The Phase 1 macOS pass already found
two bugs (a deprecated `UIFontDescriptor` API and an unsupported array-pattern `switch`)
that were invisible to every Linux check available; assume this slice can hide the same
class of bug until `xcodegen generate` + `swift build`/`xcodebuild build` run on macOS.

Pure logic added to `ScrapLabCore` (Linux-tested):

- `MaterialsChecklist.swift`: `MaterialsChecklistItem`/`MaterialsChecklistState`, flattening `ProjectWithMaterials.projectMaterials` into a checklist with required-vs-optional grouping, toggle, and "mark on hand from household inventory" — independent of SwiftUI so the completion rule (`hasEverythingRequired` only checks required items) is unit-tested.
- `RouteSegment` in `NativeLogic.swift`: ports both backend route-param validators — `isSafeRouteSegment` (`src/lib/validation/identifiers.ts`, used by `GET /api/activities/[id]`) and `resolveProject`'s `SLUG_PATTERN` (`src/lib/projects/resolve.ts`) — so a malformed deep-link slug fails client-side before a network round trip instead of only via the server's 404.
- `ActivityCategoryTheme` in `NativeLogic.swift`: ports `src/lib/categoryTheme.ts`'s one-tile-per-category-but-emoji-carries-identity rule, with a test asserting every category gets a distinct emoji and none of the reserved supervision-safety colors leak in.
- `EntitlementGate.isPremiumContentLocked(premium:plan:)`: the missing piece for gating a single activity/project card, distinct from the existing feature-level `EntitlementGate.evaluate`, which answers "can the free plan use this feature at all" rather than "is this specific item premium and the viewer free."
- **Real bug caught before it shipped:** `GET /api/activities/[id]` and `GET /api/projects/[id]` both resolve their route param by *either* UUID or slug server-side (confirmed by reading `src/app/api/activities/[id]/route.ts` and `src/lib/projects/resolve.ts` directly), but `Endpoints.activity(_:)`/`Endpoints.project(_:)` only accepted a `UUID`. That would have made `/explore/<slug>` deep links and any slug-based navigation impossible to implement. Added `Endpoints.activity(_ idOrSlug: String)` / `Endpoints.project(_ idOrSlug: String)` overloads (the `UUID` overloads now forward to these), with a regression test (`activityAndProjectEndpointsAcceptSlugsForDeepLinkLookup`) and confirmed the TypeScript endpoint scanner still matches the new interpolated path.

SwiftUI screens added under `ios-native/App/Features/Browse/` (macOS/Xcode-unverified):

- `BrowseStore`: owns the activity list, wraps the existing `BrowseCatalogPageState`/`BrowseCatalogFilters` pure state, debounces filter/search changes 350ms before refetching, and drives pagination via a per-row `.task` that calls `loadMoreIfNeeded(after:)`.
- `BrowseListView` + `BrowseFilterSheet`: search field via `.searchable`, a filter sheet for category/difficulty/age/time/energy built from the same enums the backend query builder already uses, loading/empty/error states via `SLEmptyState`.
- `ActivityCardView`: category emoji tile, title, one-liner, time/difficulty chips, supervision badge, a small sparkle mark for premium activities.
- `ActivityDetailStore` + `ActivityDetailView`: loads `GET /api/activities/{idOrSlug}`, validates the segment client-side with `RouteSegment.isSafeActivityLookup` first, shows an `UpgradeCard` instead of the body when `EntitlementGate.isPremiumContentLocked` is true for the current plan.
- `ProjectDetailStore` + `ProjectDetailView` + `MaterialsChecklistView`: loads `GET /api/projects/{idOrSlug}`, builds a `MaterialsChecklistState` from the response, same premium-gate treatment as activities.
- Wired real screens into `RootTabView`'s Browse tab and its two `navigationDestination` cases, replacing the `PlaceholderDestination` stand-ins. `AppEnvironment.swift` added as the one place the API base URL lives (both `ScrapLabAccessLoader` and the new stores now read it from there instead of a duplicated literal).

Deliberately deferred rather than half-built: no `URLCache`/offline wiring on `BrowseStore` yet (the pure `OfflineReadPolicy` groundwork exists but isn't connected), no previews added for the new screens' loading/empty/error states, `BuildLogRoute.project(UUID)` in the Build Log tab still shows a placeholder rather than reusing `ProjectDetailView` (Build Log/Library is Phase 5, left alone on purpose).

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 55 Swift tests (up from 43) |
| `swift -frontend -parse` over every file in `ios-native/App` (28 files) | Passed — syntax only, does **not** type-check SwiftUI/Observation macro usage |
| `NODE_ENV=test npx vitest run tests/api/route-inventory.test.ts --reporter=verbose` | Passed: 73 tests, including the new slug-endpoint literals |
| `NODE_ENV=test npm test` | Passed: 17 files / 161 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `git diff --check` | Passed |
| Manual grep guard: no `checkout`/`billing/portal` references, no obvious secrets, no `fatalError`/`try!` in `ios-native/App` | Passed |

**Mac-side work required before any of this is real, in order:**

1. `xcodegen generate` — the app target gained a whole new `Features/Browse` directory plus `Features/Shared/DetailPhase.swift` and `Services/AppEnvironment.swift`; confirm XcodeGen's directory glob picks all of it up.
2. `swift test` for `ScrapLabCore` on macOS — should match the 55/55 Linux result, but this is the first real confirmation since the last macOS pass (which only saw 15).
3. `xcodebuild build` (device destination, per the working recipe further down this file) — this is the first opportunity for the Swift compiler and the Observation/SwiftUI macros to actually check `BrowseStore`, `ActivityDetailStore`, `ProjectDetailStore`, and every new View body. Expect at least one real compile error given the project's own history (two Xcode-only bugs in the Phase 1 slice); do not be surprised if `@Bindable`/`@Observable` interplay, the `.task(id:)` generics, or the generic `DetailPhase<Value: Equatable>` need small adjustments.
4. Launch on the physical device (or fight through the simulator instability again) and actually browse: type a search term, apply a filter, open an activity and a project, toggle checklist items, confirm the premium gate shows for a premium item when signed out. None of this has ever rendered on a screen.
5. If step 3 turns up compile errors, fix them on the Mac, then re-run `swift test` and re-sync the fix back to this branch before continuing Phase 3 work (manual material substitutions, instructions/build-step preview, etc.).

## 2026-09-13 query/capture update — Phase 3 endpoint groundwork

Completed the next Linux-safe slice focused on Browse/detail readiness and production fixture capture workflow:

- Added typed Swift query builders for `GET /api/activities`, `GET /api/projects`, and `GET /api/materials`, preserving the backend's exact query parameter names (`age_range`, `time_max`, `energy_level`, `scrap_tag`, `cleanup_level`, `supervision_level`, comma-separated `materials`, etc.).
- Added API tests proving the query builders do not leak Swift camelCase names into backend requests and that `APIClient` appends query items to the outgoing URL.
- Added `scripts/capture-native-fixtures.mjs` plus `npm run fixtures:native:capture` to capture live API payloads into the Swift fixture directory without service-role keys. Public list/detail routes can be captured anonymously; protected routes are skipped unless `SCRAPLAB_FIXTURE_BEARER_TOKEN` is intentionally provided.
- Verified the capture script against the live Vercel deployment using a temp output directory, so it did not overwrite the checked-in representative fixtures. It captured public `activities`, `projects`, `materials`, `activity-detail`, and `project-detail` payloads; protected fixture capture correctly skipped without a bearer token.

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 43 Swift tests |
| `SCRAPLAB_FIXTURE_OUT_DIR=/tmp/scraplab-native-fixtures npm run fixtures:native:capture` | Passed: captured public live fixtures to `/tmp`, skipped protected routes without token |
| `NODE_ENV=test npx vitest run tests/api/route-inventory.test.ts --reporter=verbose` | Passed: 73 tests |
| `NODE_ENV=test npm test` | Passed: 17 files / 161 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `git diff --check` | Passed |

Mac-side still required for this slice: regenerate the Xcode project, rerun macOS `swift test`, and rerun physical-device `xcodebuild test`, because both `Endpoint.swift` and SwiftPM test resources changed. To replace representative fixtures with captured production protected-route fixtures, run `SCRAPLAB_FIXTURE_BEARER_TOKEN=<Supabase access token> npm run fixtures:native:capture` from the repo root and then rerun the Swift package tests before committing those payloads.

## 2026-09-13 early update — endpoint envelope fixture pass

Completed one more Linux-safe API compatibility slice:

- Added first-party Swift response envelope models for the app-consumable API routes the native client will decode: activities, activity detail, projects, project detail, activity recommendations, legacy recommendations, household inventory, build history, saved projects, child profiles, materials, mystery materials, scan results, and single-row mutation responses.
- Added 14 representative JSON fixtures under `ios-native/Packages/ScrapLabCore/Tests/ScrapLabModelsTests/Fixtures/` and wired the test target resources in `Package.swift`.
- Added `EndpointEnvelopeFixtureTests` to decode each envelope fixture through the production `ModelCoding.decoder()` rather than ad-hoc decoding.
- Caught and modeled a real backend shape edge: `GET /api/mystery-materials` returns partial material rows (`id`, `name`, `icon`, `category`) rather than full `Material` rows with `aliases` and `created_at`, so native now has a separate `MysteryMaterial` type instead of pretending the full model applies.
- These are local representative fixtures based on route source, not captured production payloads. Production capture remains a separate Mac/server/credential-side task before binary readiness.

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 39 Swift tests |
| `NODE_ENV=test npx vitest run tests/api/route-inventory.test.ts --reporter=verbose` | Passed: 70 tests |
| `NODE_ENV=test npm test` | Passed: 17 files / 158 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `git diff --check` | Passed |

Mac-side still required for this slice: regenerate the Xcode project because `Package.swift` now declares test resources, rerun `swift test` for `ScrapLabCore` on macOS, and rerun the physical-device `xcodebuild test` workflow. Simulator validation is still left to the known CoreSimulatorService blocker unless that host has been stabilized.

## 2026-09-12 late update — Linux-safe native logic pass

Completed another remote/Linux-safe slice before returning to Mac-only work:

- Added `ScrapLabModels/NativeLogic.swift` with pure, SwiftPM-testable native logic for:
  - `StepIllustrationAction` keyword matching, ported from the web `StepIllustration.tsx` order.
  - `EntitlementGate` decisions for free vs Plus, feature locks, recommendation limits, child-profile limits, and saved-project limits.
  - `ScanUploadPolicy` constants/validation matching `POST /api/scan-materials`: field name `image`, max 5 MB, and allowed jpeg/png/webp/heic/heif MIME types.
  - `ProjectDisplayTheme` for the eight current web slug emoji/background mappings, with an honest fallback instead of fabricated project data.
  - `NativeDeepLink`, a package-level parser covering `scraplab://...` and `scraplab:/...` forms for explore, project, build, upgrade, and auth callback routes.
  - `AccessInfoCache`, a disk cache for the last access payload so Plus UI can render from cached state before network refresh.
  - Auth/onboarding helpers: credential validation, 6-digit OTP validation, password-reset/auth state transitions, and onboarding child-profile request construction.
  - Offline/build-progress groundwork: `BuildProgressOutboxStore` for queued progress writes, `OfflineReadPolicy` for cache-vs-network decisions, and a fakeable `NetworkReachabilityProviding` seam for later `NWPathMonitor` wiring.
  - `PhotoCapturePolicy`, a pure helper for the planned 1600 px long-edge resize and 0.8 -> 0.6 JPEG quality fallback before upload.
- Replaced the app-local `DeepLink` implementation with a `typealias` to the package parser so the app and Linux package tests do not drift.
- Added package tests, raising the Linux SwiftPM package suite from 15 to 37 tests.
- Reworked the Swift endpoint scanner from nearest-token matching to initializer-scoped `Endpoint(...)` parsing, with regression coverage for multiline/interpolated paths and misleading nearby methods.
- Added `npm run audit:native-slugs`, a no-secret-safe script that confirms web/native slug maps are internally consistent and, when Supabase env vars are provided, audits that those project rows exist live.
- Added `docs/ios-domain-support-checklist.md` for the App Store support URL, privacy URL, associated-domain, privacy-manifest, and demo-account work that has to happen outside Linux.
- Added a route-inventory regression fixture proving the scanner sees forbidden native `/api/checkout`, `/api/billing/portal`, and `/api/webhooks/...` endpoints if they are ever introduced, so the existing native billing guard has coverage.

Verification from Linux:

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 37 Swift tests |
| `NODE_ENV=test npx vitest run tests/api/route-inventory.test.ts --reporter=verbose` | Passed: 70 tests |
| `NODE_ENV=test npm test` | Passed: 17 files / 158 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning in `src/app/layout.tsx` |
| `npx tsc --noEmit` | Passed |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `npm run audit:native-slugs` | Passed internal web/native slug-map consistency for 8 slugs; live Supabase row audit skipped because env vars were not provided |
| App Swift text scan for `fatalError` / `try!` under `ios-native/App` | Passed |
| `git diff --check` | Passed |

Mac-side still required for this slice: regenerate the Xcode project and run the physical-device `xcodebuild test` workflow again, because the app now imports the package-level deep-link parser through `typealias DeepLink = NativeDeepLink` and the package has new cache/native-logic/auth/offline/reachability/photo policy files. Simulator validation remains blocked by the known CoreSimulatorService instability.

## 2026-09-12 update — macOS/Xcode verification

The macOS blocker is resolved. Verified on the project's Hackintosh build host (macOS 15.7.9, Xcode 26.3):

- Installed XcodeGen 2.46.0 by building from source via SwiftPM (no Homebrew on this host).
- `xcodegen generate --spec project.yml` succeeded; confirmed the generated `App/Info.plist` retains the custom `scraplab://` URL scheme, both bundled fonts (`UIAppFonts`), camera/photo usage descriptions, light-only `UIUserInterfaceStyle`, launch background, `ITSAppUsesNonExemptEncryption`, and portrait-only orientation.
- `swift test` for `ScrapLabCore` on macOS: all 15 tests pass, matching the Linux/Docker run.
- Found and fixed two real bugs that only surface when compiled against the actual Xcode/SDK toolchain (Linux syntax-checking could not catch either):
  - `SLFont.swift` used `UIFontDescriptor.FeatureKey.typeIdentifier`/`.selectorIdentifier`, which are deprecated pre-iOS-15 names no longer present the way the code assumed on iOS 17+. Fixed to the current `.type`/`.selector` members (confirmed against the iOS 26.2 SDK's `UIFontDescriptor.h`/`UIKit.apinotes`).
  - `DeepLink.swift`'s `init?(url:)` used `case ["explore", _] where components.count == 2:` — Swift does not support a wildcard element inside an array-literal pattern (only exact-equality array literals). Rewrote the whole `switch` on `(components.first, components.count)` tuples.
- `xcodebuild test` against the iPhone 16e simulator repeatedly wedged: CoreSimulatorService stopped responding (`simctl list devices` hung indefinitely) with the `xcodebuild` process idling at 0% CPU. This recurred after a user-approved `killall`-and-restart of CoreSimulatorService, so it looks like a standing instability of this specific Hackintosh rather than a one-off. Simulator-based `xcodebuild test` remains unverified as a result.
- Fell back to a physical-device build instead: `xcodebuild build -destination 'generic/platform=iOS' -allowProvisioningUpdates` (run from Terminal.app on the Mac's console, since code signing needs the GUI-session keychain) succeeded with automatic signing under the existing team `6PA43G2WVX`. Installed and launched on a physical iPhone (14) via the direct `devicectl` binary (not `xcrun devicectl`, which is known to hang on this host) — both `device install app` and `device process launch` succeeded cleanly.
- Confirmed on-device: the five-tab shell renders (Home, Create, Build Log, Browse, Profile), Home shows the real foundation content (icon, heading, "Open foundation demo" button) rather than a placeholder, and the other four tabs show their intended Phase 1 empty-state placeholder text. Bundled fonts render (Home's heading text uses `SLFont.title`, i.e. Baloo 2).
- Follow-up: ran `xcodebuild test` against the physical device (`-destination 'platform=iOS,id=00008110-000974400A23A01E'` — note this is the classic hardware UDID `xcodebuild` needs, not the CoreDevice UUID `devicectl list devices` shows). Hit one more real bug: the `ScrapLabTests` target in `project.yml` had no `GENERATE_INFOPLIST_FILE`/`INFOPLIST_FILE` setting at all, which is silently fine when signing is disabled (the simulator run never hit it) but fatal once code signing is required. Fixed by adding `GENERATE_INFOPLIST_FILE: YES` to the `ScrapLabTests` target settings.
- After that fix: **`** TEST SUCCEEDED **`** on the physical iPhone 14. All 3 `DeepLinkTests` (`parsesGuestExploreDeepLink`, `parsesAuthenticatedBuildDeepLink`, `rejectsMalformedOrForeignDeepLinks`) pass — including direct coverage of the array-pattern bug fixed above. Phase 1 is now fully verified end-to-end on macOS/device; only the simulator path (`xcodebuild test` against `iPhone 16e`) remains unverified due to the CoreSimulatorService instability.

## Ground rules

- `ios-native/` is additive. The existing Capacitor app under `ios/` remains untouched until the explicit cutover phase.
- The Next.js API, Supabase schema/RLS/RPCs, Stripe webhooks, and RevenueCat webhooks remain the backend source of truth.
- Do everything possible on Linux first: package tests, route-contract tests, manifests, static checks, fixtures, model/API work, and web regressions.
- Do not call the native app device-ready until the generated Xcode project builds and tests on macOS.
- Native code must not reference `/api/checkout` or `/api/billing/portal`; Apple billing flows go through RevenueCat/App Store management.
- Do not commit secrets, signing material, Supabase keys, RevenueCat keys, App Store credentials, or demo credentials.

## Current summary

| Area | Status | Notes |
| --- | --- | --- |
| Branch | In progress | `feat/native-ios-foundation` |
| Foundation slice | Verified on Linux + macOS + device | Staged, independently reviewed after fixes, three real bugs found/fixed on macOS |
| Existing Capacitor `ios/` | Untouched | Still the shipping fallback |
| Swift package | Linux + macOS previously tested; latest Linux pass green | `ScrapLabModels` + `ScrapLabAPI`, 55/55 tests pass in Linux Docker after adding materials-checklist logic, route-segment validation, category theming, and slug-lookup endpoints; macOS rerun needed |
| SwiftUI app target | Builds, tests, and runs on device as of Phase 1; **untested since** | `xcodebuild test` passed on physical device for Phase 1 (3/3 `DeepLinkTests`); the new Browse/detail screens have never been compiled by Xcode, only syntax-parsed on Linux |
| Browse tab (Phase 3) | First slice written, Mac-unverified | List/search/filter + activity/project detail screens exist under `App/Features/Browse/`; needs `xcodegen generate` + a real build before it counts as working |
| Create tab (Phase 4) | First slice written, Mac-unverified | Method picker, manual picker, results, and scan screens exist under `App/Features/Create/`; highest-risk surface so far (PhotosPicker/UIImagePickerController/UIImage JPEG encoding), zero Xcode verification |
| Build/Library/Home (Phase 5) | First slice written, Mac-unverified | `App/Features/Build/`, `Features/Library/`, `Features/Home/` — 17 new files, largest untested batch yet; Home tab and Build Log tab both replaced their Phase 1 placeholders entirely |
| Profile/billing (Phase 6) | First slice written, Mac-unverified; billing is a stub boundary | `App/Features/Profile/` — 13 new files. Every tab in the app now shows real content instead of a placeholder. RevenueCat is a documented no-op (`UnconfiguredPurchaseService`) pending App Store Connect + RevenueCat dashboard setup that can only happen on a Mac with an Apple Developer account |
| API contract scanner | Implemented | Web + Swift endpoints checked against Next.js routes |
| CI | Added | Path-filtered macOS workflow, pending real GitHub/macOS run |
| macOS/Xcode | Unblocked for device workflow, but stale | Phase 1's build/sign/install/launch/test all worked on physical device; that verification predates every Browse/detail file below and must be rerun |
| Commit state | Worktree modified | `.hermes/` remains untracked and should not be committed; current native/status changes are not committed |

## Completed in current foundation slice

### Repo and project structure

- [x] Added `ios-native/` beside existing `ios/`.
- [x] Added XcodeGen project manifest at `ios-native/project.yml`.
- [x] Added generated-output ignores for `.xcodeproj`, workspaces, DerivedData, SwiftPM build output, and Fastlane output.
- [x] Added `ios-native/Makefile` with generation/test/validation entry points.
- [x] Added `ios-native/fastlane/Fastfile` and `Appfile` scaffolding.
- [x] Preserved existing Capacitor `ios/` without modifications.

### Native metadata and assets

- [x] Added `Info.plist` with camera/photo-library usage descriptions.
- [x] Added custom `scraplab://` URL scheme.
- [x] Added light-only app declaration and dark-content status bar style.
- [x] Added launch background asset matching `#F8F3EA`.
- [x] Added `PrivacyInfo.xcprivacy` placeholder manifest.
- [x] Added existing 1024 px app icon to native asset catalog.
- [x] Added Baloo 2 and Inter variable fonts with OFL licenses.
- [x] Mirrored critical plist metadata into `project.yml` `info.properties` so `xcodegen generate` does not wipe it.

### Swift package: `ScrapLabCore`

- [x] Added Linux-testable Swift 6 package under `ios-native/Packages/ScrapLabCore`.
- [x] Added `ScrapLabModels` library target.
- [x] Added `ScrapLabAPI` library target.
- [x] Ported TypeScript domain models using `UUID`, `Date`, `Codable`, `Equatable`, and `Sendable` where appropriate.
- [x] Preserved conservative supervision normalization:
  - `independent` -> `.independent`
  - `some-help` -> `.adultAssist`
  - `adult-needed` -> `.fullSupervision`
  - unknown values -> `nil`
- [x] Added central endpoint namespace for app-consumable backend routes.
- [x] Explicitly excluded Stripe checkout, billing portal, and webhooks from native endpoints.
- [x] Added bearer-token API client.
- [x] Added asymmetric coding: snake_case/date response decoding, default/camelCase request encoding.
- [x] Added typed `APIError` coverage for unauthorized, plan gate, conflict, limit reached, server, offline, and decoding cases.
- [x] Preserved structured/non-string error bodies.
- [x] Added multipart body builder.
- [x] Added typed request bodies for native mutating endpoints: activity recommendations, child profiles, household inventory, build start/progress, and saved projects.
- [x] Added Swift package tests for models, request encoding, endpoints, API client, error mapping, multipart framing, nullable access limits, supervision normalization, pure native deep-link parsing, entitlement gating, scan-upload validation, step-illustration keyword matching, slug display themes, cached access persistence, auth/OTP/onboarding reducers, offline policy/reachability seam, progress outbox persistence, and photo capture resize/compression policy.

### SwiftUI app shell and design foundation

- [x] Added `ScrapLabApp` entry point with font registration.
- [x] Added five-tab shell matching the web bottom-nav shape: Home, Create, Build Log, Browse, Profile.
- [x] Added independent typed navigation paths per tab.
- [x] Added guest-capable behavior: Browse/Create available; protected areas show sign-in nudges.
- [x] Added custom deep-link parser and pending-link replay after authentication.
- [x] Added `SessionStore` boundary for future Supabase adapter.
- [x] Added `EntitlementsStore` boundary and real `/api/me/access` loader.
- [x] Added entitlement refresh after session restore, after authentication, and when scene becomes active.
- [x] Added foundation/debug screen that can call `/api/me/access` when supplied an access token.
- [x] Added design tokens for colors, metrics, shadows, and font helpers.
- [x] Added reusable atoms: buttons, metadata/filter chips, supervision badges, empty states, and upgrade cards.
- [x] Added SwiftUI previews where practical.

### Contract tests and CI

- [x] Extended `tests/api/inventory-scanner.ts` with Swift endpoint scanning.
- [x] Normalized Swift interpolation paths like `\(id)` into route-contract placeholders.
- [x] Stripped query strings before route matching.
- [x] Excluded generated/build directories from scanner traversal.
- [x] Integrated Swift endpoint inventory into existing route-contract tests.
- [x] Added regression tests for Swift endpoint scanning and missing `ios-native` handling.
- [x] Added `.github/workflows/ios-ci.yml` path-filtered to native changes.
- [x] Added CI guard to reject native references to `/api/checkout` and `/api/billing/portal`.
- [x] Pinned CI to Xcode 26.3 on `macos-15`.

## Verification completed on Linux

| Command/check | Result |
| --- | --- |
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 37 Swift tests |
| Swift parser check over all native `.swift` files | Passed: 36 files |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `NODE_ENV=test npx vitest run tests/api/route-inventory.test.ts --reporter=verbose` | Passed: 70 tests |
| `NODE_ENV=test npm test` | Passed: 17 files / 158 tests |
| `npm run lint` | Passed: 0 errors, 1 pre-existing custom-font warning |
| `npx tsc --noEmit` | Passed |
| `npm run build` with placeholder public env | Passed, generated 48 routes/pages |
| Secret scan under `ios-native` | No committed secrets found |
| Stripe endpoint guard under `ios-native` | No native checkout/portal references found |
| Independent pre-commit review | Passed after fixes; no security concerns or logic errors |

## Blocked on macOS/Xcode

- [x] Run `xcodegen generate` from `ios-native/` on macOS.
- [x] Confirm generated `App/Info.plist` retains custom URL scheme, font declarations, camera/photo descriptions, launch metadata, orientation/device restrictions, light mode, and encryption declaration.
- [x] Run `swift test` on macOS for `ios-native/Packages/ScrapLabCore`. (15/15 pass)
- [x] Run `xcodebuild test` for the generated app target. Simulator destination remains blocked (CoreSimulatorService wedges, see below); ran successfully against a physical device instead with signing enabled — `** TEST SUCCEEDED **`, all 3 `DeepLinkTests` pass.
- [ ] Launch on simulator and verify the tab shell renders. Not verified on simulator; substituted with a physical-device launch instead (see below) since the simulator itself is unreliable on this host.
- [x] Launch on a physical device before calling Phase 1 device-demoable. Installed and launched on a physical iPhone 14 via direct `devicectl`; five-tab shell renders, Home shows real foundation content, other tabs show intended placeholder empty states.
- [x] Verify bundled fonts render in the app and previews. Confirmed on-device (Home heading uses Baloo 2 via `SLFont.title`).
- [x] Verify app icon/launch background in simulator/device. App icon renders on the home screen and at launch on the physical device.

Resolved blocker: the original "`xcodebuild` hangs before returning version/first-launch status" symptom no longer reproduces — `xcodebuild -version`, `xcodegen generate`, `swift test`, and `xcodebuild build` (device destination) all complete normally now.

New/remaining blocker: `xcodebuild test` against an iOS Simulator destination reliably wedges CoreSimulatorService (`xcrun simctl list devices` hangs indefinitely; the `xcodebuild` process idles at 0% CPU). Reproduced twice in one session, including once immediately after a `killall`-triggered restart of the service. This looks like a standing instability specific to this Hackintosh's simulator subsystem (consistent with this host's documented history of instability under load) rather than a project configuration issue. Until resolved, verify app-target changes via physical-device builds/tests rather than the simulator.

Physical-device workflow that now works end-to-end, for reference:

1. Build+sign (must run in Terminal.app on the Mac's own console — the Apple Development signing key lives in a keychain that only unlocks under a real GUI login session, not plain SSH): `xcodebuild -project ScrapLab.xcodeproj -scheme ScrapLab -destination 'platform=iOS,id=<hardware UDID>' -allowProvisioningUpdates -derivedDataPath build test`.
2. **Device ID gotcha**: `xcodebuild -destination id:...` needs the device's classic hardware UDID (e.g. `00008110-000974400A23A01E`, visible in the "Available destinations" list of a failed-destination error, or via `xcodebuild -showdestinations`), not the CoreDevice UUID that `devicectl list devices` shows (e.g. `D06B2531-DB9A-56C5-9264-B81F4935BFE5`). Using the wrong one fails fast with "Unable to find a device matching the provided destination specifier" — but that error message itself lists the correct one.
3. A `.command` file on the Desktop (double-click to run in Terminal, e.g. `~/Desktop/scrablab-test.command` this session) is a reliable way to hand off a GUI-session-only step, and avoids backslash-line-continuation paste breakage that plain multi-line copy-paste into an existing Terminal window can hit.
4. Install/launch (works fine over plain SSH, no GUI session needed): the direct `devicectl` binary (`/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl`, not `xcrun devicectl` which is known to hang on this host) — `device install app` then `device process launch`.
5. Fixed one real signing-only bug this way: the `ScrapLabTests` target in `project.yml` had no `GENERATE_INFOPLIST_FILE`/`INFOPLIST_FILE` setting, which is silently fine with signing disabled (simulator) but fatal once signing is required (device). Fixed with `GENERATE_INFOPLIST_FILE: YES` on that target.

Result: `** TEST SUCCEEDED **` on a physical iPhone 14, all 3 `DeepLinkTests` passing.

## Work to knock out before touching the Mac

### Highest-leverage Linux-safe work

- [ ] Add captured production JSON fixtures for backend responses and decode them in Swift package tests. Representative local route-shape fixtures now exist and pass, but they are not a substitute for recorded production payloads.
  - `GET /api/activities`
  - `GET /api/activities/[id]`
  - `GET /api/projects`
  - `GET /api/projects/[id]`
  - `POST /api/activity-recommendations`
  - `POST /api/recommendations`
  - `GET /api/household-inventory`
  - `GET /api/me/access`
  - `GET /api/build-history`
  - `GET /api/saved-projects`
  - `GET /api/child-profiles`
  - `GET /api/materials`
  - `GET /api/mystery-materials`
- [x] Add request-encoding tests for every currently modeled mutating endpoint body.
- [x] Add explicit endpoint scanner regression that native endpoints cannot include checkout, billing portal, or webhooks.
- [x] Make the Swift endpoint scanner more declaration-scoped/structural instead of nearest-method heuristic if it starts to get brittle.
- [x] Add `StepIllustration` keyword matcher as pure Swift logic with tests before drawing the illustrations.
- [x] Add entitlement gating pure logic tests for free vs Plus states.
- [x] Add pure URL/deep-link tests for all planned routes:
  - `/explore/<slug>`
  - `/projects/<uuid>`
  - `/build/<uuid>`
  - `/upgrade`
  - auth callback path
- [x] Add cached `AccessInfo` persistence logic and tests so Plus chrome does not flash free-tier UI on cold launch.
- [x] Add child-profile/onboarding request structs and encode tests.
- [x] Add build-progress request structs and encode tests.
- [x] Add saved-project request structs and encode tests.
- [x] Add household-inventory request structs and encode tests.
- [x] Add scan-material upload validation helpers as pure Swift logic:
  - max 5 MB
  - allowed MIME types
  - image field name `image`
- [x] Add `PhotoCaptureService` image-resize/compression design notes and pure helper tests where possible without UIKit runtime.
- [x] Add `URLCache`/offline policy skeleton that is testable without device APIs.
- [x] Add `ProgressOutbox` model and persistence tests for queued build-progress writes.
- [x] Add `NWPathMonitor` adapter boundary, leaving live monitor wiring for app/device phase.
- [x] Add production-slug audit script/test for the eight `SLUG_DISPLAY` project slugs, using safe placeholder/no-secret mode unless live credentials are intentionally provided.
- [x] Add support/privacy URL/domain checklist once `scraplab.app` decision is made. See `docs/ios-domain-support-checklist.md`.

### Phase 2 work that can start before Mac

- [ ] Add `supabase-swift` dependency only after deciding exact version and confirming package resolution strategy.
- [x] Create `AuthSessionAdapter` protocol tests and fake adapter behavior. Pure auth reducer/input validation exists; concrete Supabase adapter remains pending.
- [x] Build sign-in/sign-up view models independent of SwiftUI rendering. Covered as pure credential/state reducer groundwork; UI view models still pending once `supabase-swift` is selected.
- [x] Add OTP confirmation state machine tests.
- [x] Add onboarding child-age validation and request construction tests.
- [x] Add password reset state machine, since the plan calls it out as an open gap.

### Design-system work that can continue before Mac

- [ ] Move design-system atoms into a `ScrapLabUI` package target, or explicitly update the plan to accept app-target-only design atoms for this phase.
- [ ] Add more preview states for loading, empty, error, and plan-gated screens.
- [x] Add static SwiftUI shapes for the 10 planned `StepIllustration` actions (`StepIllustrationView`; first-pass geometry, no source SVGs to trace — expect visual rework once it can render on a screen).
- [x] Add Reduce Motion behavior for illustrations (`StepIllustrationView` gates its pulse animation on `accessibilityReduceMotion` and marks itself `accessibilityHidden`, both native-only additions the web lacks).
- [x] Add category emoji/theme dictionary port from web display helpers.
- [x] Add card/list row components needed by Browse (`ActivityCardView`); Library still pending (Phase 5).

## Phase tracker

### Phase 1 — Foundation

Status: **Complete and fully verified on macOS and physical device**.

Done:

- [x] XcodeGen spec
- [x] App target scaffold
- [x] iOS 17 baseline
- [x] Bundled fonts
- [x] Design tokens and reusable atoms
- [x] API client with typed errors
- [x] Endpoint list
- [x] Codable models
- [x] Session/auth adapter boundary
- [x] Entitlements store boundary and `/api/me/access` loader
- [x] Debug/foundation screen
- [x] Linux-verifiable tests and validation
- [x] XcodeGen/Xcode build verification (macOS, both `xcodegen generate` and `xcodebuild build`)
- [x] Device launch (physical iPhone 14, tab shell + fonts + icon confirmed)
- [x] `xcodebuild test` run on physical device (`** TEST SUCCEEDED **`, 3/3 `DeepLinkTests` pass)

Not done / intentionally deferred:

- [ ] Real Supabase sign-in adapter
- [ ] Device-demoable sign-in + plan view
- [ ] `xcodebuild test` run against an iOS Simulator destination (CoreSimulatorService wedges on this host; device run substitutes for now)
- [ ] Captured production JSON fixtures (representative local route-shape fixtures and capture script added; protected production capture still pending)
- [ ] `ScrapLabUI` package split, if keeping the original package architecture

### Phase 2 — Shell and auth

Status: **Partially scaffolded; product behavior not implemented**.

Already done:

- [x] Five-tab `TabView`
- [x] Per-tab `NavigationStack` structure
- [x] Launch background metadata
- [x] Custom URL scheme metadata
- [x] Auth/session adapter boundary
- [x] Deep-link parser/replay skeleton

Left:

- [ ] Supabase sign-in
- [ ] Supabase sign-up
- [ ] OTP email confirmation flow
- [ ] Auth callback handling with real session exchange
- [ ] Onboarding age picker
- [ ] `POST /api/child-profiles` from onboarding
- [ ] Sign out
- [ ] Password reset
- [ ] Empty authenticated Home

### Phase 3 — Browse and detail

Status: **First SwiftUI slice written on Linux; zero minutes of macOS/Xcode verification so far.**

Done (Linux-authored only — see the "Mac-side work required" list in the 2026-09-13 Browse/detail entry above before trusting any of this):

- [x] Browse list backed by `GET /api/activities` (`BrowseStore` + `BrowseListView`)
- [x] Search/filter state and debouncing (`BrowseStore` 350ms debounce + `BrowseFilterSheet` for category/difficulty/age/time/energy)
- [x] Activity detail (`ActivityDetailStore` + `ActivityDetailView`, `GET /api/activities/{idOrSlug}`)
- [x] Project detail backed by `GET /api/projects/{idOrSlug}` (`ProjectDetailStore` + `ProjectDetailView`)
- [x] Materials checklist (`MaterialsChecklistState` pure logic, Linux-tested + `MaterialsChecklistView`)
- [x] Premium gates in detail screens (`EntitlementGate.isPremiumContentLocked`, Linux-tested)
- [x] Activity/project cards (`ActivityCardView`; project cards folded into `ProjectDetailView`'s header rather than a separate list yet)
- [x] Metadata and supervision rendering in real screens (`MetadataChip`/`SupervisionBadge` wired into both detail screens and the activity card)

Left:

- [ ] Everything above needs `xcodegen generate` + a real macOS build/test/device-launch pass before it counts as done — see the ordered Mac-side list in the 2026-09-13 status entry.
- [ ] Dedicated project list/browse screen (today only reachable via `Endpoints.projects`/`ProjectsQuery`, which has no list UI yet — only single-project detail exists)
- [ ] `URLCache`/offline wiring for Browse (the pure `OfflineReadPolicy` groundwork exists but `BrowseStore` doesn't use it)
- [ ] Previews for the new screens' loading/empty/error/plan-gated states
- [ ] `BuildLogRoute.project(UUID)` in the Build Log tab still shows a placeholder instead of reusing `ProjectDetailView` (left for Phase 5 on purpose)
- [ ] Material substitutions UI (`ProjectResponse.substitutions` is decoded but not rendered)

### Phase 4 — Create flow

Status: **First SwiftUI slice written on Linux; zero minutes of macOS/Xcode verification so far** — see the "Mac-side work required" note in the 2026-09-13 Create-flow entry above before trusting any of this.

Done (Linux-authored only):

- [x] Create method picker (`CreateMethodListView`)
- [x] Manual material picker (`ManualMaterialPickerStore` + `ManualMaterialPickerView` + `MaterialTileView`)
- [x] Selection tray and age control (selection tray chips + `Stepper` in `ManualMaterialPickerView`'s bottom bar)
- [x] Recommendation results (`CreateResultsStore` + `CreateResultsView`)
- [x] Gemini suggestion cards (`AiSuggestionCardView`)
- [x] Scan flow with PhotosPicker (`ScanView`)
- [x] Camera capture wrapper (`CameraCapture`, a thin `UIImagePickerController` representable)
- [x] Image downscale/recompression (`PhotoUploadPreparer`, wrapping the existing pure `PhotoCapturePolicy`)
- [x] Multipart upload integration (`ScanStore`, using the existing `MultipartFormData` builder)
- [x] 403 plan gate UI (`ScanStore.phase == .planGate` → `UpgradeCard`; also handled in `CreateResultsStore` for symmetry even though `/api/activity-recommendations` doesn't currently return one)
- [x] 429 daily-limit UI (`CreateResultsStore.phase == .limitReached` → `SLEmptyState`)

Left:

- [ ] Everything above needs `xcodegen generate` + a real macOS build/test/device-launch pass before it counts as done — this phase in particular exercises `PhotosPicker`, `UIImagePickerController`, and `UIImage` JPEG encoding, none of which Linux can touch at all.
- [ ] Household-staple pre-selection for Plus users in the manual picker (web-only today via an extra `/api/household-inventory` call)
- [ ] Camera/photo-library permission prompt behavior has never actually fired in this app — Phase 1 added the `Info.plist` strings but nothing exercised them until this slice
- [ ] Offline handling for a scan/recommendation request made while offline (falls through to the generic `.failed` message today, no queueing)

### Phase 5 — Build and library

Status: **First SwiftUI slice written on Linux; zero minutes of macOS/Xcode verification so far** — see the "Mac-side work required" note in the 2026-09-13 Build-and-library entry above before trusting any of this. This is the largest single batch of new App-target files across Phases 3–5, so treat it as the highest-risk phase to date.

Done (Linux-authored only):

- [x] Build step player (`BuildPlayerStore` + `BuildPlayerView`)
- [x] `POST /api/build-history` (start-or-resume, fired once per session when signed in)
- [x] `PATCH /api/build-history/[id]` (fire-and-forget per step, awaited on Complete)
- [x] Pause/resume lifecycle (Pause fires the `abandoned` PATCH and returns to project detail; resume reads the persisted `currentStep` back on next load)
- [x] Completion celebration (`BuildCompleteStore` + `BuildCompleteView`, static confetti dots)
- [x] Step illustrations (`StepIllustrationView`, ten `Canvas`-drawn shapes — first-pass approximations, not a pixel port, see above)
- [x] Saved library tab (`LibraryView`'s Saved tab + `SavedProjectCardView`)
- [x] Build-history library tab (`LibraryView`'s History tab + `BuildHistoryRowView`)
- [x] Home sections: greeting, weekly progress, quick nav, continue building, household staples (all six, including "Suggested For You" backed by the real `featured=true` endpoint instead of mock data)

Left:

- [ ] Everything above needs `xcodegen generate` + a real macOS build/test/device-launch pass before it counts as done.
- [ ] Offline progress outbox — the pure `BuildProgressOutboxStore`/`OfflineReadPolicy` groundwork exists (added in an earlier Linux-safe slice) but `BuildPlayerStore` doesn't queue through it yet; a step PATCH made while offline is silently dropped today rather than queued for reconnect. This is the one item from the plan's own "offline is the capability that matters most" warning that remains unwired.
- [ ] Collections tab in Library (permanent stub, matches the web exactly — not a gap, a deliberate parity choice)
- [ ] Household-staple pre-selection / `?tab=saved` deep-selection into Library (minor web conveniences not ported, noted rather than silently dropped)

### Phase 6 — Profile and billing

Status: **First SwiftUI slice written on Linux; zero minutes of macOS/Xcode verification so far.** Billing specifically is also blocked on real-world setup (App Store Connect + RevenueCat dashboard) that has to happen before the boundary below can be implemented for real — see the "Mac-side work required" note in the 2026-09-13 Profile-and-billing entry above.

Done (Linux-authored only; billing is client-side plumbing against a documented no-op boundary, not a working purchase flow):

- [x] Profile header (`ProfileView`)
- [x] Kids CRUD (`ChildProfilesStore` + `KidsSectionView`)
- [x] Household staples/profile inventory UI (`HouseholdStaplesStore` + `StaplesSectionView`)
- [x] Delete account flow (`DeleteAccountSectionView`)
- [x] RevenueCat SDK integration — **boundary only**: `PurchaseServicing` protocol + `UnconfiguredPurchaseService`; the real `RevenueCat` SPM package is not added and cannot be from this environment (see above)
- [x] `Purchases.logIn(supabaseUserId)` on every sign-in — call site wired in `ScrapLabApp` (`purchaseService.configure(appUserID:)`), no-ops against the unconfigured boundary today
- [x] RevenueCat logout on sign-out — call site wired (`purchaseService.logOut()`), same caveat
- [x] Purchase Plus (`SubscriptionStore.purchase()`, boundary-backed)
- [x] Restore purchases (`SubscriptionStore.restore()`, boundary-backed)
- [x] `POST /api/me/sync-revenuecat` (real network call, only the purchase result feeding it is stubbed)
- [x] Apple's subscription management URL (`SubscriptionStore.openManagement()`, boundary-backed)
- [x] Build mystery and challenges (`MysteryBuildStore`/`MysteryBuildView`, `ChallengesView`)
- [x] Static privacy policy view (`PrivacyPolicyView`, ported verbatim from `src/app/privacy/page.tsx`)

Left:

- [ ] Everything above needs `xcodegen generate` + a real macOS build/test/device-launch pass before it counts as done.
- [ ] The actual RevenueCat integration: App Store Connect subscription product, RevenueCat dashboard entitlement, the SPM package dependency, and a real `PurchaseServicing` adapter — this is real-world account/business setup, not something further Linux-side code can produce.
- [ ] StoreKit sandbox testing of one purchase and one restore, once the above exists.

### Phase 7 — Submission and cutover

Status: **Not started**.

Left:

- [ ] Final privacy manifest required-reason API audit
- [ ] App Privacy nutrition label
- [ ] Age rating 4+
- [ ] Support URL
- [ ] Privacy policy URL
- [ ] `scraplab.app` domain and associated-domain setup
- [ ] Pre-confirmed Plus demo account for App Review
- [ ] Dynamic Type pass
- [ ] VoiceOver pass
- [ ] Reduce Motion pass
- [ ] Screenshots
- [ ] TestFlight upload
- [ ] App Review submission
- [ ] Release
- [ ] Seven-day soak
- [ ] Cutover PR deleting Capacitor/EAS only after soak

## Cutover checklist — do not start early

Only after SwiftUI build is approved, released to all users, and soaked for seven days with no rollback-worthy crash:

- [ ] Delete `ios/`
- [ ] Delete `capacitor-shell/`
- [ ] Delete `capacitor.config.ts`
- [ ] Delete `app.json`
- [ ] Delete `eas.json`
- [ ] Delete `credentials.json`
- [ ] Delete `.github/workflows/release-ios.yml`
- [ ] Remove Capacitor/RevenueCat web-native package entries and `cap:*` scripts from `package.json`
- [ ] Remove web-native glue imports from:
  - `src/app/layout.tsx`
  - `src/lib/auth-context.tsx`
  - `src/app/subscription/page.tsx`
  - `src/components/ui/UpgradeActions.tsx`
  - `src/app/create/scan/page.tsx`
  - `src/app/profile/page.tsx`
- [ ] Revoke dead `EXPO_TOKEN`
- [ ] Run `npm run build`, `npm test`, `npm run lint`, and `npx tsc --noEmit`

## Update protocol for this file

Update this file whenever:

- A native commit lands.
- A phase starts or ends.
- A blocker is discovered or cleared.
- A Linux-safe task is completed before macOS work resumes.
- Verification evidence changes.

Each update should include:

1. What changed.
2. What was verified, with exact commands where practical.
3. What remains blocked on macOS/device validation.
4. Any scope decision that diverges from `NATIVE_IOS_REWRITE_PLAN.md`.
