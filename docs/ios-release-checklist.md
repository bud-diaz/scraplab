# Native iOS TestFlight Release Checklist

Setup required before `.github/workflows/ios-release.yml` ("Native iOS Release", manual `workflow_dispatch` trigger) can successfully upload a build. This is a one-time setup per Apple Developer team/App Store Connect app; the workflow itself needs no further changes once these exist.

## App Store Connect API key (for signing + upload)

The workflow authenticates to Apple entirely via an App Store Connect API key — no Apple ID/password, no 2FA prompts, no separately-managed distribution certificate or provisioning profile (Xcode's automatic signing fetches/creates those itself using the key, via `-allowProvisioningUpdates`).

- [ ] In App Store Connect, go to **Users and Access → Integrations → App Store Connect API**, generate a key with **App Manager** (or higher) access.
- [ ] Download the `.p8` key file once — Apple only lets you download it a single time.
- [ ] Add three repo secrets (**Settings → Secrets and variables → Actions**):
  - `APP_STORE_CONNECT_API_KEY_ID` — the Key ID shown in App Store Connect.
  - `APP_STORE_CONNECT_API_ISSUER_ID` — the Issuer ID shown above the key list.
  - `APP_STORE_CONNECT_API_KEY_CONTENT` — the `.p8` file's contents, base64-encoded (`base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy`).

## Runtime config (for a working, not just shipping, build)

Without these, the workflow still produces and uploads a build, but every tester hits the same "Supabase is not configured in this build yet" wall this session found and fixed for local Mac builds — these three values are what `ios-native/Config/Local.xcconfig` holds locally, written fresh in CI from secrets instead (see `Config/Runtime.example.md`). They're public, client-embeddable keys (not secrets in the security sense — the anon key is protected by Supabase Row Level Security, not secrecy), but still not committed to the repo.

- [ ] `SCRAPLAB_SUPABASE_URL` — e.g. `https://your-project.supabase.co`.
- [ ] `SCRAPLAB_SUPABASE_ANON_KEY` — the Supabase project's anon/public key.
- [ ] `SCRAPLAB_REVENUECAT_IOS_API_KEY` — RevenueCat's public iOS SDK key (optional — a blank value ships a build where purchases show a human-readable "not configured" state rather than crashing, per the app's existing `UnconfiguredPurchaseService` fallback).

## Apple Developer team

- [ ] Confirm the App Store Connect API key's team matches `team_id("6PA43G2WVX")` in `ios-native/fastlane/Appfile` and `DEVELOPMENT_TEAM` in `ios-native/Config/Base.xcconfig`.
- [ ] Confirm an app record for `com.scraplab.app` already exists in App Store Connect — `upload_to_testflight` uploads a build to an existing app, it doesn't create one.

## First run

- [ ] Trigger the workflow once by hand (**Actions → Native iOS Release → Run workflow**) after the secrets above are set, and confirm the build appears in App Store Connect → TestFlight before relying on it for a real release.
- [ ] `MARKETING_VERSION` in `ios-native/Config/Base.xcconfig` is the user-facing version (currently `1.0`) — bump it manually before a release that should show a new version number; the build number itself is set automatically per CI run (`GITHUB_RUN_NUMBER`), so it doesn't need manual bumping.
