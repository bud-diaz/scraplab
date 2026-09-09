# ScrapLab iOS — App Store Privacy & Compliance Worksheet

This is a working reference for filling out App Store Connect correctly on
first submission. It is not itself a legal document — it's the answer key
for two App Store Connect forms (App Privacy, Age Rating) plus a punch list
of non-code items that block submission. Read the caveats inline; a few
answers depend on account-side configuration (Gemini API tier, RevenueCat
SDK version) this repo can't see, and are flagged as such.

Grounded in the actual data flows in this codebase as of this branch:
- `supabase/migrations/001_initial.sql` (schema: `profiles`, `child_profiles`,
  `saved_projects`, `build_history`, `household_inventory`)
- `src/app/api/scan-materials/route.ts` + `src/lib/ai/vision.ts` (photo →
  Gemini flow: the image is sent to Google's Gemini API and never written to
  our own database or storage — there's no Supabase Storage usage anywhere
  in this codebase)
- `src/lib/native/purchases.ts` (RevenueCat client)
- `src/app/api/webhooks/stripe/route.ts`, `src/app/api/webhooks/revenuecat/route.ts`

---

## 1. App Privacy ("nutrition label") — App Store Connect → App Privacy

The label is filled out **per data type Apple defines**, and only covers
data the **iOS app** collects — not the web app's Stripe flow, which is out
of scope for this label. Answer each type below as: **Collected?** →
**Linked to identity?** → **Used for tracking?** → **Purpose**.

| Data type | Collected? | Linked to you? | Tracking? | Purpose |
|---|---|---|---|---|
| **Email Address** | Yes | Yes | No | App Functionality, Account Management |
| **Name** (child's first name, `child_profiles.name`) | Yes | Yes* | No | App Functionality |
| **Photos or Videos** (material-scan photo) | Yes | See note | No | App Functionality |
| **User ID** (Supabase auth user id) | Yes | Yes | No | App Functionality |
| **Purchase History** (plan/entitlement status) | Yes | Yes | No | App Functionality |
| **Product Interaction** (build history, saved projects, materials on hand) | Yes | Yes | No | App Functionality |
| **Device ID** (RevenueCat SDK — see note) | Likely Yes | Yes | No | App Functionality; Fraud Prevention/Security |
| Financial Info (card numbers, billing address) | **No** | — | — | Handled entirely by Apple; never reaches ScrapLab's servers |
| Health & Fitness | No | — | — | — |
| Location | No | — | — | — |
| Contacts | No | — | — | — |
| Browsing/Search History | No | — | — | — |
| Diagnostics (crash/performance data) | No\*\* | — | — | — |
| Sensitive Info | No | — | — | — |

\* **Judgment call, confirm before submitting:** the scan photo is processed
in-memory and never persisted (see `vision.ts` — the base64 image is sent
to Gemini and discarded once a response returns), so it's defensible to mark
it **"not linked to you"** since it isn't stored in a way that's associated
with your identity in our systems. If you'd rather be conservative, mark it
**linked** — either is defensible, but be consistent with what the privacy
policy says (currently: "we do not save a copy of the photo").

\*\* **Diagnostics: No** is correct only if you have not added a crash
reporter (Sentry, Firebase Crashlytics, etc.) — none is in this codebase
today. If you add one before submitting, update this row and the label.

**RevenueCat Device ID — verify against your actual SDK version.**
RevenueCat's SDK may collect a device/vendor identifier for fraud
prevention and to associate purchases with a device. RevenueCat publishes
an App Privacy answer guide for exactly this in their dashboard/docs —
check it against the `@revenuecat/purchases-capacitor` version actually
shipped (pinned in `package.json`) before finalizing this row, since their
guidance is updated as their SDK changes.

**Not applicable to this label at all:** Stripe payment data. Stripe is
only used by the *web app*; the iOS binary never calls Stripe. Don't
declare Stripe-related data types on the iOS App Privacy label.

**Bottom line:** no data type here should be marked **"Used for Tracking"**
— ScrapLab has no advertising SDK and does not correlate ScrapLab data with
data from other companies' apps/websites for ads or data-broker purposes.
If that ever changes (e.g. adding an ad network or analytics SDK that does
cross-app tracking), this whole label needs revisiting, along with an ATT
(AppTrackingTransparency) prompt.

---

## 2. Age Rating questionnaire — App Store Connect → App Information

Answer every content-frequency question **"None"** — ScrapLab has no
violence, sexual/suggestive content, profanity, horror themes, gambling,
alcohol/tobacco/drug references, or user-generated content shared between
users. Specific ones worth calling out by name:

| Question | Answer | Why |
|---|---|---|
| Unrestricted Web Access | **No** | The WKWebView only ever navigates within `allowNavigation` in `capacitor.config.ts` (the app's own domain + Stripe checkout hosts) — it is not a general-purpose browser. |
| Contests | No | — |
| Gambling / simulated gambling | No | A subscription is not a loot box or wager. |
| Age restrictions on in-app purchases | N/A | ScrapLab Plus is a standard auto-renewable subscription. |
| Made for Kids | **No — do not enroll** | See §3. |

Expected result: **4+**.

---

## 3. Category — do not use the Kids Category

Do **not** enable Apple's dedicated **Kids Category** for this app, and do
not answer "Made for Kids" as yes in App Store Connect. Reasoning:

- The Kids Category requires every third-party SDK in the binary to be on
  Apple's human-reviewed kids-category-safe list, and requires a **parental
  gate** in front of anything leaving the app (purchases, external links,
  data collection beyond what's on that list). ScrapLab ships Supabase,
  Google's Gemini SDK/API, and RevenueCat — none of these are the kind of
  SDKs pre-cleared for that program, and re-certifying them is a real
  undertaking, not a config toggle.
- More fundamentally, ScrapLab's actual end user *inside the app* is the
  parent: they sign in, enter materials, manage the subscription, and set
  up kid profiles. The child doesn't operate the account. That's a normal
  **Utilities / Lifestyle / Education**-category app, not a kids-category
  app, and the standard age-rating questionnaire above already gets you to
  4+ without the Kids Category's much stricter SDK and parental-gate rules.

Recommended primary category: **Utilities** or **Lifestyle** (either is
defensible; pick whichever App Store Connect's category list makes closer
competitors sit under).

---

## 4. Submission-blocking items outside this repo's reach

These aren't nutrition-label or age-rating answers — they're separate
requirements that will cause a rejection regardless of how the label is
filled out. None of them were in scope for the Capacitor/RevenueCat build
work already on this branch; flagging them now so they don't surface for
the first time during review.

1. **In-app account deletion — done.** `src/app/api/me/delete-account/route.ts`
   (a `DELETE` handler, gated by `requireAuth`) cancels any active Stripe
   subscription for the user and then calls
   `createServiceClient().auth.admin.deleteUser(user.id)`, which cascades
   through every user-owned table via the existing FK constraints
   (`child_profiles`, `saved_projects`, `build_history`,
   `household_inventory` all `references profiles(id) on delete cascade`,
   and `profiles(id) references auth.users(id) on delete cascade`). The UI
   is a "Delete Account" control in Profile → Danger Zone
   (`src/app/profile/page.tsx`), with an inline confirm step that warns the
   deletion is permanent and, for a Plus subscriber, tells them whether
   their subscription is cancelled automatically (Stripe/web) or needs to
   be cancelled separately via their Apple ID settings (Apple/RevenueCat —
   there is no API for a developer to force-cancel a StoreKit subscription,
   so this is expected, not a gap). This has not been exercised against a
   real Supabase project or a live Stripe test-mode subscription — do one
   manual QA pass on both paths before relying on it for submission.
2. **Privacy Policy URL**: point App Store Connect's privacy policy field
   at `https://<your-production-domain>/privacy` once the production domain
   in `capacitor.config.ts` is finalized and deployed — the page itself
   (`src/app/privacy/page.tsx`) is already live in this branch.
3. **Support URL**: App Store Connect requires one; confirm you have a real
   support contact (the privacy policy currently points to
   `privacy@scraplab.app` — confirm this inbox exists and is monitored, or
   swap in the real address before publishing the page).
4. **Xcode Privacy Manifest (`PrivacyInfo.xcprivacy`)**: Apple requires a
   privacy manifest declaring "required reason" API usage for the app
   target and for any third-party SDK that touches those APIs. Capacitor
   and RevenueCat's own packages generally ship their own manifests, but
   verify in Xcode (Product → Archive → Validate) that no manifest warnings
   surface for the `App` target itself — this can't be checked without
   Xcode, which isn't available in this environment.
5. **Gemini API tier**: `.env.example` currently documents the Gemini
   *free tier* (AI Studio). Google's terms for that free tier permit using
   submitted content to improve their products; the paid Vertex AI tier
   does not. This affects the accuracy of the privacy policy's Google
   section and potentially the App Privacy label's "used to improve the
   product" nuance. Decide which tier you're actually running in
   production and adjust the privacy policy's Google paragraph
   (`src/app/privacy/page.tsx`) to match before publishing.
