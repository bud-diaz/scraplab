# ScrapLab iOS Domain, Support, and Review Checklist

This is the non-code App Store checklist that should be closed before Phase 7 submission. It is intentionally separate from the native implementation so the Mac/Xcode pass does not have to rediscover product/account work.

## Required before TestFlight/App Review

- [ ] Confirm the production domain for the app. Current assumed domain: `scraplab.app`.
- [ ] Confirm `https://scraplab.app/privacy` resolves to the deployed privacy policy page.
- [ ] Confirm `https://scraplab.app/support` exists, or choose a different support URL for App Store Connect.
- [ ] Confirm `privacy@scraplab.app` exists and is monitored, or update `src/app/privacy/page.tsx` before submission.
- [ ] Confirm the support URL and privacy URL are entered in App Store Connect.
- [ ] Confirm Supabase redirect allowlist includes `com.scraplab.app://auth-callback` before enabling native magic-link fallback.
- [ ] Do not enable Associated Domains until `scraplab.app` can serve a valid `apple-app-site-association` file.

## App Store Connect answers to carry forward

- Age rating target: **4+**.
- Kids Category: **No / do not enroll**.
- Tracking: **No** unless an ad/cross-app tracking SDK is added later.
- Non-exempt encryption: **false**, matching `ITSAppUsesNonExemptEncryption = false`.
- Stripe payment data is web-only and should not be declared as iOS-collected financial data.

## Mac/Xcode validation items

- [ ] Archive or validate the app in Xcode and confirm there are no privacy-manifest warnings from the app target or third-party SDKs.
- [ ] Re-check RevenueCat's App Privacy guidance against the exact native SDK version selected in Phase 6.
- [ ] Decide whether material-scan photos are marked linked or not linked to identity in App Privacy; keep it consistent with the published privacy policy.
- [ ] If a crash reporter is added, update both this checklist and `docs/ios-app-store-compliance.md` diagnostics rows.

## Demo account

- [ ] Create a pre-confirmed App Review demo account.
- [ ] Give that account Plus entitlement before submission.
- [ ] Put credentials and test notes in App Review notes, not in the repo.
