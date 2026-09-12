# ScrapLab: native SwiftUI iOS app

## Context

ScrapLab ships on iOS today as a Capacitor shell with no product code in it. `ios/App/App/SceneDelegate.swift` installs a stock `CAPBridgeViewController`, and `capacitor.config.ts` points `server.url` at `https://scraplab-inky.vercel.app`. The App Store binary is a WKWebView over the live website.

That has three costs:

- **Review risk.** A wrapper with no native functionality is the classic App Store guideline 4.2 rejection. The release workflow has never successfully run, so this has not been tested against review yet.
- **No offline story at all.** Cold launch navigates to Vercel. When that fails the user gets `capacitor-shell/www/index.html`, a spinner with a Retry button. Nothing else works.
- **Web constraints leak into the product.** Safe-area padding hacks, a floating CSS pill for the tab bar, `window` events standing in for lifecycle, and a splash screen the web app has to remember to dismiss.

The project's own roadmap already anticipated this. `SCRAPLAB_ECOSYSTEM_SCOPE.md` lists the responsive web app as the initial platform and native mobile apps as the next one.

This plan replaces the iOS client with a native SwiftUI app while keeping everything behind it. The Next.js API routes on Vercel stay as the backend unchanged. The web app keeps running but is frozen. The Capacitor build keeps shipping until the SwiftUI app reaches parity, then it is swapped in one cutover.

**Outcome:** a real iOS app, built and shipped from this repo, calling the same API the web client calls today.

## What changes and what does not

| Area | Decision |
| --- | --- |
| `src/app/api/*` on Vercel | Unchanged. Swift calls the same 24 routes. |
| Supabase schema, RLS, RPCs | Unchanged. |
| Stripe and RevenueCat webhooks | Unchanged. |
| Next.js web client | Stays deployed, frozen, no new features. |
| `ios/`, `capacitor-shell/`, Capacitor deps, EAS | Deleted, but only at cutover. |
| iOS client | Rewritten in SwiftUI from scratch. Roughly 5,600 lines of TSX to replace. |
| Release pipeline | EAS Build to GitHub Actions on macOS runners. |

## Why the backend needs no changes

`getUserFromRequest` in `src/lib/db/client.ts:1` reads `Authorization: Bearer <token>` and verifies it with `supabase.auth.getUser(token)`. There are no cookies and no session middleware. Every protected route goes through `requireAuth` in `src/lib/db/auth.ts`.

So a Swift client signs in with `supabase-swift`, puts the access token in a header, and consumes the existing routes as they stand. This is the single fact that makes the rewrite a client-only project.

Keeping the API also keeps the security model intact. Migration `supabase/migrations/011_recommendation_usage.sql` revokes `SELECT` on `projects` and `activities` from `anon` and `authenticated` precisely so premium redaction cannot be bypassed, and all five Postgres RPCs are granted to `service_role` only. Talking to Supabase directly for content would mean redesigning that.

## Repo layout

The Xcode project lives beside the Next.js app in the same repo, so the API contract and its client move together.

```
ios-native/                     new — the native app
  project.yml                   XcodeGen manifest, committed
  ScrapLab.xcodeproj            generated, gitignored
  Makefile                      make gen / open / test
  Config/                       Base, Debug, Release xcconfig
  App/
    ScrapLabApp.swift           @main, font registration, RevenueCat configure
    Info.plist
    PrivacyInfo.xcprivacy
    Assets.xcassets
    Navigation/                 AppState, Route, TabRouter, RootTabView, DeepLinkHandler
    Features/
      Home/ Auth/ Create/ Browse/ Library/ Build/ Profile/ Paywall/
    Services/                   SessionStore, EntitlementsStore, PurchaseService,
                                PhotoCaptureService, Haptics, Connectivity, ProgressOutbox
  Packages/ScrapLabCore/
    Sources/ScrapLabModels/     pure Codable, no dependencies
    Sources/ScrapLabAPI/        APIClient, Endpoints, APIError, multipart
    Sources/ScrapLabUI/         design system, components, illustrations
    Tests/                      + Fixtures/*.json recorded from production
  ScrapLabUITests/              three smoke tests
  fastlane/Fastfile
ios/                            existing Capacitor shell — untouched until cutover
```

Three choices worth stating:

**`ios-native/` as a sibling of `ios/`, not a replacement.** The Capacitor shell is the shipping vehicle until cutover. Two directories with zero interaction means no chance of breaking the live build while the rewrite is in progress. Optionally rename to `ios/` after the deletion commit, though the rename invalidates every CI cache key for no real gain.

**XcodeGen over a checked-in `.xcodeproj`.** This project will add roughly 150 Swift files over its life. With a committed `project.pbxproj` every file addition mutates a machine-generated file that cannot be meaningfully reviewed or merged, and this repo works branch-per-feature. XcodeGen globs directories, so adding a file needs no manifest edit. The manifest also owns the settings that are currently invisible tribal knowledge in the Capacitor pbxproj: deployment target, `DEVELOPMENT_TEAM = 6PA43G2WVX`, bundle id, schemes. Cost is one `brew install xcodegen`, absorbed by the Makefile. Tuist is overkill for one app and one package.

**One app target plus one local package with three library targets, not five feature packages.** `ScrapLabModels`, `ScrapLabAPI` and `ScrapLabUI` compile and test in seconds via `swift test` with no simulator, which is exactly where you want fast feedback. They also enforce the one dependency rule that actually decays in flat projects: the design system cannot import a feature, and models cannot import the API client. Feature *folders* inside the app target give organization without five more `Package.swift` files and cross-package preview breakage.

## Deletion sequence

Nothing Capacitor-related is removed until the SwiftUI app is in TestFlight and accepted. Until then the current shell remains the shipping app.

Define cutover precisely: the SwiftUI build is approved, released to all users, and has soaked for seven days with no rollback-worthy crash. Until then `release-ios.yml` and EAS stay wired as the hotfix path.

At cutover, in one PR: delete `ios/`, `capacitor-shell/`, `capacitor.config.ts`, `app.json`, `eas.json`, `credentials.json`, `.github/workflows/release-ios.yml`, the eleven Capacitor and RevenueCat entries in `package.json` including the three `cap:*` scripts, and `src/components/native/NativeBootstrap.tsx`, `src/lib/native/camera.ts`, `src/lib/native/purchases.ts`.

That deletion breaks live imports, so the same PR must edit five web files. This is the single sanctioned exception to the freeze, and it should be mechanical only:

| File | What breaks |
| --- | --- |
| `src/app/layout.tsx` | mounts `<NativeBootstrap />` |
| `src/lib/auth-context.tsx` | imports `configureRevenueCat` |
| `src/app/subscription/page.tsx:35` | the whole native purchase branch collapses to Stripe |
| `src/components/ui/UpgradeActions.tsx:22` | `isNativeIOS` plus the `scraplab:refresh-plan` listener |
| `src/app/create/scan/page.tsx` | imports `captureNativePhoto` |

`src/app/profile/page.tsx:396` also calls `isNativeIOS()`, for the Apple-subscription wording in the delete-account copy. After the PR, `npm run build` and the Vitest suite must stay green.

Keep every iOS secret except `EXPO_TOKEN`, which becomes dead and should be revoked.

Keep `NSCameraUsageDescription` from `ios/App/App/Info.plist:32` and the `#F8F3EA` splash background from the launch storyboard. Both carry over verbatim.

## Deployment target

Raise from iOS 15.0 to **iOS 17.0**. That unlocks `@Observable`, `NavigationStack` with typed paths, `ContentUnavailableView` for the eight empty states, `PhotosPicker`, and `ShareLink`. The alternative is `ObservableObject` plus `NavigationView` and hand-rolled equivalents, which is materially more code for an audience that skews toward recent devices. Set `TARGETED_DEVICE_FAMILY` to iPhone only; the web layout has no iPad design and shipping a stretched one invites review comments.

## The API client

One `APIClient` actor in `Sources/Networking/`. It owns the base URL, injects the bearer token from `AuthStore`, and decodes into the model types.

**Token handling.** `supabase-swift` refreshes the session itself. `APIClient` asks `AuthStore` for the current access token on each request rather than caching one, so a refresh mid-session is invisible to callers.

**Typed errors.** The web client branches on raw status codes in a dozen places. Collapse that into one enum decoded once:

```
enum APIError: Error {
  case unauthorized            // 401 → present the sign-in sheet
  case planGate(feature: …)    // 403 → present UpgradeCard
  case conflict                // 409 → already saved, treat as success
  case limitReached(…)         // 429 with upgradeRequired: true
  case server(status: Int, message: String?)
  case offline
  case decoding(Error)
}
```

Every screen then switches on `APIError` instead of comparing integers. This is where `src/lib/access/index.ts` limits and the `upgradeRequired` flag land on the client side.

**Endpoints as a namespace, not stringly-typed URLs.** One `Endpoint` value per route, so the compiler catches a typo that `tests/api/route-inventory.test.ts` currently has to catch with an AST scan.

Two currently-unused routes come back into service. `GET /api/projects/[id]` and `GET /api/recommendations` have no caller in the web client because the pages that need them are server-rendered. `src/app/projects/[id]/page.tsx`, `src/app/explore/[slug]/page.tsx` and `src/app/build/[id]/complete/page.tsx` reach Supabase through the service-role client and always redact to the free tier, so a signed-in Plus user gets gated content and then refetches. In Swift those screens make one authenticated request and get the correct tier back directly. The rewrite simplifies them rather than porting the split.

**The error body is not always a string.** Zod validation failures return `{ error: <flattened object> }` while every other failure returns `{ error: "some string" }`. A naive `struct { let error: String }` throws a `DecodingError` on every 400 and masks the real problem. Decode leniently: try `String`, fall back to a generic JSON value, and surface a generic message rather than raw validation output. Parents should never see a Zod dump.

**Casing is asymmetric, and this is the detail most likely to cost a day.** Responses are raw database rows in snake_case (`user_id`, `staple_flag`, `one_liner`, `premium_only`) inside camelCase envelopes (`{ savedProjects: [...] }`, `{ matches, aiSuggestions }`). Request bodies are camelCase (`projectId`, `childProfileId`, `stapleFlag`, `currentStep`, `materialIds`).

So set `keyDecodingStrategy = .convertFromSnakeCase` and `keyEncodingStrategy = .useDefaultKeys`. The decode strategy is a no-op on keys that are already camelCase, so the envelopes decode with no `CodingKeys` at all. Then write small dedicated `Encodable` request structs whose property names match each Zod schema exactly. That is about 40 lines against roughly 400 lines of hand-written `CodingKeys`. The one rule to document on the decoder: never re-encode a decoded response as a request body, because the casing will not round-trip.

**Codable models.** Mirror `src/types/index.ts` one-to-one, in `ScrapLabModels`. Two decisions worth making deliberately:

- **Type ids as `UUID`, not `String`.** The `isUuid()` guards in `src/lib/validation/identifiers.ts` exist only because `src/lib/mock-data.ts` injects fake string ids. Typing ids as `UUID` makes that bug class unrepresentable and forces the mock-data debt to be resolved at the data layer.
- **Keep `Activity.supervisionLevel` a `String`** with a computed `normalizedSupervision: SupervisionLevel?` porting `src/lib/activities/supervision.ts`. Decoding straight into an enum would be lossy, and `nil` has to render "Supervision level unknown" rather than nothing. `SupervisionBadge` must never omit itself; the comment in `src/components/ui/SupervisionBadge.tsx` says why.

**Multipart.** `POST /api/scan-materials` takes a `multipart/form-data` field named `image`, ≤5 MB (413), MIME in jpeg/png/webp/heic/heif (415), per `src/app/api/scan-materials/route.ts:7`. One small `MultipartBody` builder handles it, with `URLSession.upload(for:from:)` over prebuilt `Data` rather than a streamed body.

`PhotoCaptureService` should downscale to 1600 px on the long edge, encode JPEG at quality 0.8 matching the Capacitor `quality: 80`, and re-compress at 0.6 if the result still exceeds 5 MB so the user never sees a 413. A 12 MP iPhone capture easily blows the cap, and Gemini gains nothing from the extra pixels.

Offer both entry points. `PhotosPicker` cannot take a live photo, so camera capture needs a thin `UIImagePickerController` wrapper, with library picking as the secondary action. **That means adding `NSPhotoLibraryUsageDescription` to Info.plist.** Only `NSCameraUsageDescription` exists today, so library picking would crash on launch of the picker.

**One entitlements store.** Today `usePlanAccess` fires `GET /api/me/access` independently from `BottomNav`, `TopNav`, `PlanUsageIndicator`, `/create/manual` and three sections of `/profile`. Replace all of it with a single `EntitlementsStore` in the environment, refreshed on sign-in, on `scenePhase == .active`, and after a purchase. That also replaces the `scraplab:refresh-plan` window event `NativeBootstrap` dispatches.

## State and navigation

Two `@Observable` stores in the environment, and nothing else global:

- **`SessionStore`** wraps `supabase-swift`. Holds `user`, `session`, `isLoading`. Everything else in the app is screen-local `@State`.
- **`EntitlementsStore`** as above. Persist the last `AccessInfo` to disk so a cold launch renders Plus chrome for a Plus subscriber instead of flashing free-tier UI while the network resolves.

**Fix a latent identity bug while porting RevenueCat.** `src/lib/native/purchases.ts:17` calls `Purchases.configure({ appUserID })` once per process behind a module-level `configured` flag. If one user signs out and another signs in without an app relaunch, the second inherits the first user's RevenueCat identity, and `/api/me/sync-revenuecat` looks up `subscribers/${user.id}`, so entitlements can cross accounts. In Swift, configure anonymously at launch, then call `Purchases.shared.logIn(supabaseUserId)` on every sign-in and `logOut()` on every sign-out. Assert that `appUserID` equals the session user id whenever a session exists.

**Navigation.** A five-tab `TabView` matching `src/components/layout/BottomNav.tsx:8`: Home, Create, Build Log, Browse, Profile. Each tab owns a `NavigationStack` with its own typed path enum. The screens that are deliberately full-bleed today (`/auth`, `/onboarding`, `/build/[id]/complete`) present modally outside the tab bar, which is what `AppShell` opts them out of on the web.

**Deep links.** Register a custom `scraplab` scheme in Phase 1 and Associated Domains on `scraplab.app` in Phase 6, once the domain exists and can serve an `apple-app-site-association` file. Map `/explore/<slug>` to the Browse tab, `/projects/<uuid>` to a pushed detail, `/build/<uuid>` to the build player cover, and `/upgrade` to the paywall sheet. A deep link received while signed out routes to sign-in and replays afterward.

**Email confirmation: use a 6-digit OTP, not the magic link.** This is the sharpest edge in the migration. Today `emailRedirectTo` points at `/auth/callback`, and `src/app/auth/callback/page.tsx` waits for the hash token then checks `/api/child-profiles` to pick onboarding or home.

Sign up, then have the user type the code from the email, then `verifyOTP(email:token:type:.signup)`. That is immune to the most common mobile onboarding failure, which is the confirmation email being opened on a laptop or inside Gmail's in-app browser. It also works in the Simulator and, critically, for an App Review tester, and it needs no Associated Domains, no `apple-app-site-association`, and no change to the frozen web app. Supabase email templates can carry `{{ .Token }}` and `{{ .ConfirmationURL }}` together, so one template serves both clients. Enabling it is a dashboard change.

Build the link path too, cheaply: add `com.scraplab.app://auth-callback` to Supabase's redirect allowlist and handle it in `onOpenURL`. And if a user confirms on another device, they simply sign in with their password. Whichever path resolves the session, the post-confirmation logic is unchanged: an empty `/api/child-profiles` means show onboarding.

## Design system port

`Sources/DesignSystem/` gets four files that are close to mechanical translations of the `@theme` block in `src/app/globals.css:5`.

- **`SLColor.swift`** — the full token list as static `Color` values, defined in Swift rather than an asset catalog so it stays greppable and diffable against `globals.css`. Note the token names are legacy and the values are current: `builder-500` is Craft Orange `#F4934B`, not the old Builder Blue, and `cream-50` is Soft Lavender `#EDEBFB`, not cream. Ship both the literal ramp and semantic aliases, and have feature code use the aliases: `primary`, `hero`, `pageBackground`, `surface`, `ink`, `bodyText`, `mutedText`, `line`. This repo has already been through one rebrand; the aliases make the next one a one-file change.
- **`SLFont.swift`** — Baloo 2 for headings, Inter for body, static TTFs from Google Fonts under the SIL Open Font License. Use `Font.custom(_:size:relativeTo:)` so Dynamic Type works, which is both an accessibility expectation and a review smoke test.
- **`SLSpacing.swift` / `SLRadius.swift`** — spacing 4/8/12/16/20/24/32/40/48/64, radii 16/20/28, capsule for pills, 32 for sheet tops.
- **`SLShadow.swift`** — the three card elevations as `ViewModifier`s.

Three mechanical details that are easy to get wrong:

**Tabular figures do not come from `.monospacedDigit()`.** That modifier only applies to system fonts. Inter ships a `tnum` feature but SwiftUI will not reach it. Build a `UIFontDescriptor` with `kNumberSpacingType` and `kMonospacedNumbersSelector`, then wrap it as a `Font`. Apply it everywhere the web uses the `.tabular` utility: step counters, usage counts, ages, times.

**Register fonts in code, not only via `UIAppFonts`.** Ship them as package resources and register through `CTFontManagerRegisterGraphicsFont` from a helper called by both the app entry point and the preview helpers. If you rely on the app target's Info.plist alone, every `#Preview` inside the design-system package renders in system font, which defeats the point of previewing the design system.

**CSS blur radius is about twice the SwiftUI shadow radius.** Both card shadows are two-layer and SwiftUI takes one shadow per modifier, so each becomes two chained `.shadow` calls, and CSS `8px` blur maps to SwiftUI `radius: 4`. Skipping this conversion is the usual reason a ported design looks heavier than the web original.

Then `ViewModifier`s for the reused atoms: `Button` (4 variants, 3 sizes, always capsule, `scaleEffect` on press), `MetadataChip`, `FilterChip`, `SupervisionBadge`, `EmptyState`, `UpgradeCard`. These cover most of `src/components/ui/`.

Two things need decisions rather than translation:

- **`StepIllustration.tsx`** matches keywords in a step title to one of 10 animated SVGs. The SVGs are geometric primitives only, circles, ellipses, rects and short paths with single quadratic curves, so hand-port each to a SwiftUI `Shape` in a fixed 80×80 space, roughly 25 to 45 lines apiece and about a day and a half total. An SVG to PDF vector imageset is the escape hatch but introduces a manual asset pipeline and loses independent tinting. Port `getStepAction` as ten ordered `contains` checks; order matters, since a step titled "Cut and roll" must yield cut. Two things the web version lacks and the native one needs: honor `accessibilityReduceMotion` by rendering the static pose, and mark every illustration `accessibilityHidden`, since the instruction text carries the meaning.
- **Emoji as category identity.** `src/lib/categoryTheme.ts` deliberately uses one lavender tile for every category with the emoji carrying identity, because the palette reserves green, amber and coral for supervision safety. Keep that rule exactly. The project hero emoji and background map in `src/lib/display.ts:19` ports as a dictionary.

No dark mode today. Declare the app light-only in Info.plist rather than shipping a half-working dark palette.

## Phases

Each phase ends in something that runs on a device. Estimates assume one developer.

**Phase 1 — Foundation.** About one week.
XcodeGen spec, app target, iOS 17 baseline, bundled fonts, the four design-system files, the atom modifiers with SwiftUI previews. `APIClient` with typed errors, the `Endpoint` list, Codable models for every type in `src/types/index.ts`. `AuthStore` on `supabase-swift`, `EntitlementsStore`. A throwaway debug screen that signs in and prints `GET /api/me/access`.
*Demoable:* sign in, see your plan.
*Start in parallel, long lead time:* register `scraplab.app`, point it at the deployment, stand up `/support`, and confirm the eight `SLUG_DISPLAY` project slugs are real rows.

**Phase 2 — Shell and auth.** About one week.
Five-tab `TabView`, per-tab `NavigationStack`, launch screen at `#F8F3EA`, dark status bar content. Sign in, sign up, the email-confirmation deep link, onboarding age picker writing to `POST /api/child-profiles`. Sign out.
*Demoable:* a new user can get from launch to an empty Home.

**Phase 3 — Browse and detail.** About one and a half weeks.
`/explore` with debounced search and the category, difficulty, time and age filters over `GET /api/activities`. `/explore/[slug]` detail. `/projects/[id]` detail with `MaterialsChecklist` and the premium gate. Activity and project cards, metadata chips, supervision badges.
*Demoable:* the content library is fully browsable. This is the phase that proves the design system.

**Phase 4 — Create flow.** About two weeks.
`/create` methods list, `/create/manual` material picker with search, category chips, selection tray and age control, and `/create/results` rendering activity matches plus the Gemini suggestion cards. `/create/scan` with `PhotosPicker` and camera capture, JPEG re-encode, multipart upload, the 403 plan gate and the 429 daily-limit state.
*Demoable:* the core product loop works end to end.

**Phase 5 — Build and library.** About one and a half weeks.
`/build/[id]` step player writing `POST /api/build-history` and `PATCH /api/build-history/[id]` on each step, pause and complete. `StepIllustration` assets. `/build/[id]/complete` celebration. `/library` with Saved and History tabs. Home assembled from `GreetingRow`, `WeeklyProgress`, `QuickNavRow`, `ContinueBuilding` and `HouseholdStaples`.
*Demoable:* full parity minus billing and profile.

**Phase 6 — Profile and billing.** About one and a half weeks.
`/profile` split into four views: header, kids CRUD, staples (Plus only), delete account. `/subscription` and `/upgrade` on the RevenueCat SDK with entitlement `plus`, `Purchases.logIn(supabaseUserId)`, purchase, restore, and Apple's management URL, followed by `POST /api/me/sync-revenuecat`. `/build/mystery` and `/challenges`. Privacy policy as a static view.
*Demoable:* feature-complete. This is the TestFlight build.

**Phase 7 — Submission and cutover.** About one week.
`PrivacyInfo.xcprivacy` with the required-reason API declarations, App Privacy nutrition label from the answer key in `docs/ios-app-store-compliance.md`, age rating 4+, support URL, privacy policy URL, `ITSAppUsesNonExemptEncryption = false`. Create the pre-confirmed Plus demo account for App Review. Dynamic Type, VoiceOver and Reduce Motion passes. Screenshots. Then TestFlight, submission, release, a seven-day soak, and the deletion pull request.

Roughly nine to ten weeks of focused work, which is closer to three months of calendar time at a realistic solo pace. Budget for one rejection round. The two screens most likely to overrun are Profile, which is four independent CRUD sections with three different gating rules, and the build player, which is the only screen with write-path persistence, offline concerns and a modal lifecycle.

## Testing

The Vitest and Playwright suites test the server and the frozen web client. Keep all 19 files and the `check` job exactly as they are. `tests/api/*` stays the contract test for the API the Swift app consumes, which is the most valuable coverage in the repo.

On the Swift side, test what has logic rather than what has pixels:

- **Unit tests (Swift Testing).** Codable round-trips for every model against captured JSON fixtures, the supervision normalizer, `APIError` mapping from each status code, the multipart body builder, the `StepIllustration` keyword matcher, and the entitlement gating rules.
- **Previews instead of snapshot tests.** Every design-system atom and every screen state, including loading, empty, error and plan-gated, gets a preview. That replaces most of what `tests/ui/*.tsx` does today without a snapshot-diff maintenance burden.
- **One UI test.** Launch, sign in, browse to an activity, open it. Enough to catch a broken launch or a broken navigation stack, not a regression suite.

Stub at the `URLProtocol` level, not behind a repository protocol. That exercises the real client, the real encoder and decoder, and the real error mapping. Mocking a repository protocol tests only the mock.

The fixture-decoding suite is the most valuable Swift tests in the project. Record real JSON from production for all 24 endpoints into `Tests/Fixtures/` and assert each decodes. It is the only thing standing between a server-side field rename and a crashed client in the field.

**Close the contract gap that the rewrite opens.** `tests/api/route-inventory.test.ts` proves every frontend `fetch` resolves to a real route and method, but `tests/api/inventory-scanner.ts` only scans `src/app` and `src/components`. Swift call sites are invisible to it, so the iOS app could drift from the API with nothing failing until a user hits it. Fix it by keeping every path literal in one `Endpoints.swift` and adding a Swift scanner to `inventory-scanner.ts` that extracts `"/api/..."` literals with their adjacent method and feeds them through the existing `findMatchingRoute`. That is about 50 lines, runs on the existing Linux CI with no Xcode, and preserves a guarantee this repo already decided was worth having.

## CI/CD

**A new `ios-ci.yml`** on a macOS runner, path-filtered to `ios-native/**`. Pin the Xcode version explicitly rather than using the runner default, or a runner-image bump breaks an unrelated pull request. Cache SPM keyed on `Package.resolved`, run `xcodegen generate`, then `swift test` on the package (fast, no simulator) and `xcodebuild test` on the app with `CODE_SIGNING_ALLOWED=NO`. Budget 8 to 12 minutes. macOS minutes bill at ten times the Linux rate, which is exactly why the path filter matters.

Add one guard to that job: fail the build if `api/checkout` or `billing/portal` appears anywhere under `ios-native/`. That makes App Store guideline 3.1.1 a mechanical check instead of a thing to remember.

**`ci.yml`** keeps its `check` job on `ubuntu-latest` and its `e2e` job gated on `STAGING_URL`. Add `paths-ignore` for `ios-native/**` only if `check` is not a required status check. If it is required, `paths-ignore` leaves it pending forever on Swift-only pull requests, so just let it run on cheap Linux minutes.

**`release-ios.yml`** is rewritten for a macOS runner with Fastlane and stays `workflow_dispatch` only, matching the current file's own warning against automatic release. Every existing secret carries over: `IOS_DIST_CERTIFICATE_BASE64`, `IOS_DIST_P12_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `ASC_API_KEY_BASE64`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`. Use `setup_ci` for an ephemeral keychain, `import_certificate` from a decoded `.p12` in the runner temp directory, manual signing, `build_app`, then `upload_to_testflight`. Keep the `if: always()` credential cleanup.

**Build number continuity is a real trap.** The bundle id and App Store Connect record stay the same, so the SwiftUI app is a new version of the existing app and its `CFBundleVersion` must exceed the highest build EAS ever uploaded. Use `latest_testflight_build_number + 1`, not the workflow run number, which will collide and be rejected.

Promotion from TestFlight to the App Store stays manual for the first several releases.

## Risks and open questions

**Home's "Suggested For You" row has no API.** `src/app/page.tsx` renders six hardcoded projects from `src/lib/mock-data.ts`. That is not shippable in a native app that cannot quietly fall back to sample content. Resolve it with `GET /api/activities?featured=true&limit=10`, which `src/app/api/activities/route.ts:41` already supports and which already applies premium redaction. 58 of the 100 seeded activities carry `featured: true`, so the row fills. Personalize it for free by adding an `age_range` bucket derived from the signed-in user's first child profile, reusing the same bucketing `/api/activity-recommendations` already does. Zero server changes, and strictly better than a hardcoded list. A real `GET /api/home` that excludes already-built activities and weights by household inventory is worth doing after the iOS app ships, not before.

**The mock-data debt should not be ported.** Do not carry over a line of `src/lib/mock-data.ts`. Typing ids as `UUID` makes the `isUuid()` guard class unrepresentable. As a Phase 1 data task, confirm the eight project slugs in the `SLUG_DISPLAY` map at `src/lib/display.ts:19` exist as real rows in `projects` with real UUIDs, and write a seed migration if they do not. Where a screen has no data it shows an empty state, never fabricated content. That is a reduction in behavior versus the web app, and it is the right trade.

**No illustration assets exist.** The app is emoji throughout while `new_scraplab-design-spec.md` asks for soft-3D illustration. This is a content decision, not an engineering one. Ship emoji for v1 and treat illustration as a later visual upgrade, since the design system is built to swap the tile contents without touching layout.

**Offline behavior is a new capability, not a port.** Three cheap tiers, folded into the phases rather than given their own. First, a `URLCache` on the client session, which makes a repeat activities fetch instant. Second, explicit disk persistence for the three things that gate the first screen: last `AccessInfo`, last child profiles, last featured page. Third, `NWPathMonitor` driving an offline banner plus a `ProgressOutbox`, a small on-disk queue of pending build-progress writes flushed on reconnect.

The outbox is the one that matters. The build player must keep working once its steps are loaded. Losing a child's progress because the Wi-Fi dropped mid-craft is the worst failure this product has. Full offline build playback for un-opened projects stays out of scope.

**Stripe must not be reachable from the binary.** `POST /api/checkout` and `POST /api/billing/portal` stay server routes for the web, and the Swift `Endpoint` list must not include them. Profile's manage-subscription action opens Apple's management URL, never the Stripe portal. The CI grep guard enforces this.

**A reviewer cannot confirm an email.** This is the most likely avoidable rejection for this app. Email confirmation is on, and every gated feature needs a Plus entitlement. Create a pre-confirmed, Plus-entitled demo account and put the credentials in the App Review notes. Without it a reviewer cannot get past the sign-up screen.

**Guest browsing must survive the port.** The web app lets guests browse, with the recommendation quota keyed on a hashed IP. A native app that walls the front door behind sign-up converts worse. The tab shell should render fully without a session: Browse and Create work, Library and Profile show the sign-in nudge.

**Review blockers to close in Phase 7.** `PrivacyInfo.xcprivacy` does not exist and is now required; verify RevenueCat's bundled manifest is picked up in the aggregated privacy report. There is no support URL and no live `scraplab.app`, both of which have long lead times, so start the domain in Phase 1. Account deletion already exists via `DELETE /api/me/delete-account`. Rate 4+ and do not opt into the Kids Category, which triggers parental-gate requirements on every outbound link and a third-party SDK prohibition that RevenueCat complicates. Sign in with Apple is not required while Supabase email and password is the only method, but adding any social login makes it mandatory.

**Two clients now share one unversioned API.** Once a binary is in users' hands a field rename breaks installs you cannot force-update. Adopt an additive-only rule for response shapes and re-record the Swift fixtures from production periodically, since they only catch drift if they are current.

**Open question: password reset.** No flow exists anywhere in the codebase. On the web a user can at least be helped manually. In a native app a forgotten password is a dead end. Recommend adding `resetPasswordForEmail` in Phase 2, which is a small addition to `AuthStore` and a deep-link handler, with no server change.

## Verification

Per phase, on a real device rather than only the simulator:

1. **API parity.** For each screen, compare the native result against the same action in the web app signed in as the same user. The two clients hit identical routes, so any divergence is a client bug.
2. **Plan gating.** With a free account, confirm the scan screen, mystery build and staples all present the upgrade card, and that the fourth recommendation of the day returns the daily-limit state. With a Plus account, confirm all four unlock. `tests/api/recommendation-access.test.ts` documents the expected behavior.
3. **Purchase flow.** Buy Plus in the StoreKit sandbox, confirm the entitlement store updates, then confirm `profiles.plan` flips in Supabase via the `sync-revenuecat` call. Then confirm a Stripe-subscribed account is not clobbered, which is the invariant `tests/api/revenuecat-sync.test.ts` locks in.
4. **Build lifecycle.** Start a build, advance three steps, force-quit, relaunch, confirm it resumes at the same step. Then complete it and confirm `completion_status` is `completed`.
5. **Auth round trip.** Sign up with a fresh address, confirm by email, confirm the deep link opens the app into onboarding rather than Safari.
6. **Offline.** Airplane mode on each tab. Cached content renders, everything else shows the offline state, nothing spins forever.
7. **Regression on the server.** `npm run lint`, `npx tsc --noEmit` and `npm test` must stay green throughout, since the API is unchanged. Any failure means the rewrite touched something it should not have.

