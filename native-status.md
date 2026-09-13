# Native iOS Rewrite Status

Tracking file for work against [`NATIVE_IOS_REWRITE_PLAN.md`](./NATIVE_IOS_REWRITE_PLAN.md). Update this between commits and phase boundaries so the repo shows what is done, what is still Linux-verifiable, and what is blocked on macOS/Xcode.

_Last updated: 2026-09-12 on `feat/native-ios-foundation`._

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
| Swift package | Linux + macOS tested | `ScrapLabModels` + `ScrapLabAPI`, 15/15 tests pass natively |
| SwiftUI app target | Builds, tests, and runs | `xcodebuild test` passes on physical device (3/3 `DeepLinkTests`); simulator destination still blocked |
| API contract scanner | Implemented | Web + Swift endpoints checked against Next.js routes |
| CI | Added | Path-filtered macOS workflow, pending real GitHub/macOS run |
| macOS/Xcode | Unblocked for device workflow | Build/sign/install/launch/test all work on physical device; CoreSimulatorService is unstable on this host specifically |
| Commit state | Staged | `.hermes/` remains untracked and should not be committed |

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
- [x] Added Swift package tests for models, request encoding, endpoints, API client, error mapping, multipart framing, nullable access limits, and supervision normalization.

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
| `docker run --rm -v "$PWD/ios-native/Packages/ScrapLabCore:/workspace:ro" -w /workspace swift:6.0-noble swift test --scratch-path /tmp/scraplab-build` | Passed: 15 Swift tests |
| Swift parser check over all native `.swift` files | Passed: 26 files |
| `make validate` in `ios-native/` | Passed: YAML, plist, privacy manifest, asset JSON |
| `NODE_ENV=test npx vitest run tests/api/route-inventory.test.ts --reporter=verbose` | Passed: 69 tests |
| `NODE_ENV=test npm test` | Passed: 17 files / 157 tests |
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

- [ ] Add recorded JSON fixtures for backend responses and decode them in Swift package tests.
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
- [ ] Add explicit endpoint scanner regression that native endpoints cannot include checkout, billing portal, or webhooks.
- [ ] Make the Swift endpoint scanner more declaration-scoped/structural instead of nearest-method heuristic if it starts to get brittle.
- [ ] Add `StepIllustration` keyword matcher as pure Swift logic with tests before drawing the illustrations.
- [ ] Add entitlement gating pure logic tests for free vs Plus states.
- [ ] Add pure URL/deep-link tests for all planned routes:
  - `/explore/<slug>`
  - `/projects/<uuid>`
  - `/build/<uuid>`
  - `/upgrade`
  - auth callback path
- [ ] Add cached `AccessInfo` persistence logic and tests so Plus chrome does not flash free-tier UI on cold launch.
- [ ] Add child-profile/onboarding request structs and encode tests.
- [ ] Add build-progress request structs and encode tests.
- [ ] Add saved-project request structs and encode tests.
- [ ] Add household-inventory request structs and encode tests.
- [ ] Add scan-material upload validation helpers as pure Swift logic:
  - max 5 MB
  - allowed MIME types
  - image field name `image`
- [ ] Add `PhotoCaptureService` image-resize/compression design notes and pure helper tests where possible without UIKit runtime.
- [ ] Add `URLCache`/offline policy skeleton that is testable without device APIs.
- [ ] Add `ProgressOutbox` model and persistence tests for queued build-progress writes.
- [ ] Add `NWPathMonitor` adapter boundary, leaving live monitor wiring for app/device phase.
- [ ] Add production-slug audit script/test for the eight `SLUG_DISPLAY` project slugs, using safe placeholder/no-secret mode unless live credentials are intentionally provided.
- [ ] Add support/privacy URL/domain checklist once `scraplab.app` decision is made.

### Phase 2 work that can start before Mac

- [ ] Add `supabase-swift` dependency only after deciding exact version and confirming package resolution strategy.
- [ ] Create `AuthSessionAdapter` protocol tests and fake adapter behavior.
- [ ] Build sign-in/sign-up view models independent of SwiftUI rendering.
- [ ] Add OTP confirmation state machine tests.
- [ ] Add onboarding child-age validation and request construction tests.
- [ ] Add password reset state machine, since the plan calls it out as an open gap.

### Design-system work that can continue before Mac

- [ ] Move design-system atoms into a `ScrapLabUI` package target, or explicitly update the plan to accept app-target-only design atoms for this phase.
- [ ] Add more preview states for loading, empty, error, and plan-gated screens.
- [ ] Add static SwiftUI shapes for the 10 planned `StepIllustration` actions.
- [ ] Add Reduce Motion behavior for illustrations.
- [ ] Add category emoji/theme dictionary port from web display helpers.
- [ ] Add card/list row components needed by Browse and Library.

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
- [ ] Captured production JSON fixtures
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

Status: **Not started beyond endpoint/model/design groundwork**.

Left:

- [ ] Browse list backed by `GET /api/activities`
- [ ] Search/filter state and debouncing
- [ ] Activity detail
- [ ] Project detail backed by `GET /api/projects/[id]`
- [ ] Materials checklist
- [ ] Premium gates in detail screens
- [ ] Activity/project cards
- [ ] Metadata and supervision rendering in real screens

### Phase 4 — Create flow

Status: **Not started beyond endpoint/API groundwork**.

Left:

- [ ] Create method picker
- [ ] Manual material picker
- [ ] Selection tray and age control
- [ ] Recommendation results
- [ ] Gemini suggestion cards
- [ ] Scan flow with PhotosPicker
- [ ] Camera capture wrapper
- [ ] Image downscale/recompression
- [ ] Multipart upload integration
- [ ] 403 plan gate UI
- [ ] 429 daily-limit UI

### Phase 5 — Build and library

Status: **Not started beyond endpoint/model groundwork**.

Left:

- [ ] Build step player
- [ ] `POST /api/build-history`
- [ ] `PATCH /api/build-history/[id]`
- [ ] Pause/resume lifecycle
- [ ] Completion celebration
- [ ] Step illustrations
- [ ] Saved library tab
- [ ] Build-history library tab
- [ ] Home sections: greeting, weekly progress, quick nav, continue building, household staples
- [ ] Offline progress outbox

### Phase 6 — Profile and billing

Status: **Not started beyond endpoint/model/entitlement groundwork**.

Left:

- [ ] Profile header
- [ ] Kids CRUD
- [ ] Household staples/profile inventory UI
- [ ] Delete account flow
- [ ] RevenueCat SDK integration
- [ ] `Purchases.logIn(supabaseUserId)` on every sign-in
- [ ] RevenueCat logout on sign-out
- [ ] Purchase Plus
- [ ] Restore purchases
- [ ] `POST /api/me/sync-revenuecat`
- [ ] Apple's subscription management URL
- [ ] Build mystery and challenges
- [ ] Static privacy policy view

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
