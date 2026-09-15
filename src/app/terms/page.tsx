import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";

// Effective date is intentionally a plain constant, not build-time `new
// Date()` — it should only change when these terms' substance changes,
// not on every deploy. Keep in sync with the effective date in
// src/app/privacy/page.tsx if both change together.
const EFFECTIVE_DATE = "September 15, 2026";

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mb-6">
      <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-2">{title}</h2>
      <div className="text-sm font-body text-walnut-700 leading-relaxed space-y-2">{children}</div>
    </section>
  );
}

export default function TermsOfUsePage() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader
          title="Terms of Use"
          subtitle={`Effective ${EFFECTIVE_DATE}`}
        />
        <div className="px-4 pb-12">
          <p className="text-sm font-body text-walnut-700 leading-relaxed mb-6">
            These Terms of Use (&ldquo;Terms&rdquo;) govern your use of ScrapLab&rsquo;s website and
            apps (together, the &ldquo;Service&rdquo;). By creating an account or using the Service,
            you agree to these Terms. If you don&rsquo;t agree, don&rsquo;t use the Service.
          </p>

          <Section title="Who can use ScrapLab">
            <p>ScrapLab is built for and operated by parents, caregivers, and educators — not by children directly. You must be at least 18 years old to create an account. Any kid profile you add is information you enter on behalf of a child you supervise; ScrapLab does not collect information directly from children, and a child does not operate the account.</p>
          </Section>

          <Section title="Your account">
            <p>You&rsquo;re responsible for the accuracy of the information you provide and for keeping your login credentials secure. You&rsquo;re responsible for activity that happens under your account. Let us know right away if you suspect unauthorized access.</p>
          </Section>

          <Section title="Subscriptions and billing">
            <p><strong>Free and Plus plans.</strong> ScrapLab offers a free plan with limited daily recommendations, and ScrapLab Plus, a paid auto-renewing subscription that unlocks unlimited recommendations, photo material scanning, additional kid profiles, and other features described in the app.</p>
            <p><strong>Billing.</strong> On the web, ScrapLab Plus is billed through Stripe. On iOS, it&rsquo;s billed through your Apple ID via In-App Purchase. Your subscription automatically renews for the same period and price unless you cancel at least 24 hours before the end of the current period. Payment is charged to your payment method at confirmation of purchase and at the start of each renewal period.</p>
            <p><strong>Cancellation.</strong> Cancel anytime — through the billing portal on the web (Stripe) or through your Apple ID subscription settings on iOS (Settings → your name → Subscriptions). Canceling stops future renewals; it doesn&rsquo;t refund the current billing period. Because these are two independent billing systems, canceling one does not cancel the other — if you subscribed on both, cancel each separately.</p>
            <p><strong>Refunds.</strong> Refunds for web (Stripe) purchases are handled at ScrapLab&rsquo;s discretion — contact us using the details below. Refunds for App Store purchases are handled by Apple under its own refund policies; ScrapLab cannot issue those refunds directly.</p>
            <p><strong>Price changes.</strong> We&rsquo;ll give you reasonable notice before any price increase takes effect on your next renewal.</p>
          </Section>

          <Section title="Project safety — please read">
            <p>ScrapLab suggests build projects using household materials, filtered by age range and labeled with a supervision level (independent, check-in, adult-assist, or full supervision). These labels are guidance, not a substitute for your own judgment as the supervising adult. You are solely responsible for supervising children during any build, assessing whether a project and its materials are appropriate and safe for your specific child and situation, and following the stated supervision level. ScrapLab is not liable for injury, property damage, or other harm arising from a build project, to the fullest extent permitted by law.</p>
          </Section>

          <Section title="Content you provide">
            <p>You&rsquo;re responsible for the materials, photos, and other content you submit to ScrapLab (for example, a photo submitted to the material scanner). Don&rsquo;t submit photos of people, including children — the scanner is intended for photos of household materials only. You retain ownership of what you submit; you grant ScrapLab a limited license to process it (including sending scan photos to our AI vision provider) solely to operate the Service, as described in our <a href="/privacy" className="text-builder-500 font-semibold">Privacy Policy</a>.</p>
          </Section>

          <Section title="Acceptable use">
            <p>Don&rsquo;t use the Service to: violate any law; upload content that infringes someone else&rsquo;s rights or contains malicious code; attempt to access accounts or data that aren&rsquo;t yours; interfere with or disrupt the Service; or reverse-engineer or scrape the Service beyond normal use.</p>
          </Section>

          <Section title="ScrapLab's content">
            <p>The project library, recommendation logic, branding, and other ScrapLab-created content are owned by ScrapLab and protected by intellectual property law. We grant you a personal, non-exclusive, non-transferable license to use the Service for your own household or classroom use — not to republish or redistribute ScrapLab&rsquo;s content commercially.</p>
          </Section>

          <Section title="Third-party services">
            <p>The Service relies on third-party providers — Supabase (database and authentication), Google&rsquo;s Gemini API (photo material detection), Stripe (web payments), and Apple/RevenueCat (iOS subscriptions). Their own terms and policies also apply to the parts of the Service they support.</p>
          </Section>

          <Section title="Disclaimers">
            <p>The Service is provided &ldquo;as is&rdquo; without warranties of any kind, to the fullest extent permitted by law. We don&rsquo;t guarantee that project suggestions are error-free, that materials on hand will always produce a perfect match, or that the Service will be uninterrupted or error-free.</p>
          </Section>

          <Section title="Limitation of liability">
            <p>To the fullest extent permitted by law, ScrapLab is not liable for indirect, incidental, special, consequential, or punitive damages, or for any loss of data, arising from your use of the Service. Our total liability for any claim relating to the Service is limited to the amount you paid ScrapLab in the 12 months before the claim arose.</p>
          </Section>

          <Section title="Termination">
            <p>You can stop using the Service and delete your account at any time from Profile → Delete Account. We may suspend or terminate accounts that violate these Terms. Sections that by their nature should survive termination (like Subscriptions and billing for amounts already owed, and Limitation of liability) will survive.</p>
          </Section>

          <Section title="Changes to these Terms">
            <p>We may update these Terms from time to time. If we make material changes, we&rsquo;ll update the effective date above and, where appropriate, notify you directly. Continuing to use the Service after changes take effect means you accept the updated Terms.</p>
          </Section>

          <Section title="Governing law">
            <p>These Terms are governed by the laws of the United States and the state in which ScrapLab is established, without regard to conflict-of-law principles.</p>
          </Section>

          <Section title="Contact us">
            <p>Questions about these Terms? Email us at{" "}
              <a href="mailto:privacy@scraplab.app" className="text-builder-500 font-semibold">privacy@scraplab.app</a>.
            </p>
          </Section>
        </div>
      </div>
    </AppShell>
  );
}
