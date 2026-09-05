import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";

// Effective date is intentionally a plain constant, not build-time `new
// Date()` — it should only change when this policy's substance changes,
// not on every deploy.
const EFFECTIVE_DATE = "September 5, 2026";

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="mb-6">
      <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-2">{title}</h2>
      <div className="text-sm font-body text-walnut-700 leading-relaxed space-y-2">{children}</div>
    </section>
  );
}

export default function PrivacyPolicyPage() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader
          title="Privacy Policy"
          subtitle={`Effective ${EFFECTIVE_DATE}`}
        />
        <div className="px-4 pb-12">
          <p className="text-sm font-body text-walnut-700 leading-relaxed mb-6">
            ScrapLab (&ldquo;ScrapLab,&rdquo; &ldquo;we,&rdquo; &ldquo;us&rdquo;) helps parents and
            caregivers turn household materials into safe, age-appropriate build
            projects for kids. This policy explains what information we collect
            when you use the ScrapLab app or website, why we collect it, and the
            choices you have. ScrapLab is built for and used by parents and
            caregivers — not by children directly.
          </p>

          <Section title="Information we collect">
            <p><strong>Account information.</strong> When you create a ScrapLab account, we collect your email address and password (handled by our authentication provider, Supabase — we never see or store your password in plain text).</p>
            <p><strong>Kid profiles.</strong> If you add a profile for your child, we store the first name (optional) and age you enter, so recommendations can be filtered to what&rsquo;s age-appropriate. This information is entered by you, the parent or caregiver — ScrapLab does not collect any information directly from children.</p>
            <p><strong>Materials and build activity.</strong> We store the materials you select or scan, your saved &ldquo;household staples,&rdquo; the projects you save, and your build history (which projects you started or completed, and which kid profile you built them for), so ScrapLab can give you better recommendations over time.</p>
            <p><strong>Photos for material scanning.</strong> If you use the photo scanner (a ScrapLab Plus feature), the photo you take is sent to our AI vision provider to detect which materials are visible, and the result is returned to your device. We do not save a copy of the photo — it is processed to produce a list of detected materials and then discarded. Photos of household materials are the intended use of this feature; please don&rsquo;t include photos of people, including children, when using the scanner.</p>
            <p><strong>Subscription and payment information.</strong> If you subscribe to ScrapLab Plus, payment is handled entirely by Apple (via In-App Purchase, on iOS) or Stripe (on the web) — ScrapLab never receives or stores your card number. We do store your subscription status (e.g. &ldquo;Plus&rdquo; or &ldquo;Free&rdquo;) so the app knows which features to unlock.</p>
            <p><strong>Usage information.</strong> Standard technical information (like error logs) may be collected automatically to keep ScrapLab reliable and secure.</p>
          </Section>

          <Section title="How we use your information">
            <p>We use the information above to: generate and personalize build recommendations; remember your household&rsquo;s materials and kid profiles between visits; manage your account and subscription; keep the service safe and reliable; and communicate with you about your account (for example, a receipt or a support reply).</p>
            <p>We do not use your information, or your child&rsquo;s information, to serve targeted or behavioral advertising, and we do not sell personal information.</p>
          </Section>

          <Section title="Who we share information with">
            <p>We work with a small number of service providers who process data on our behalf, under their own privacy and security commitments:</p>
            <ul className="list-disc pl-5 space-y-1">
              <li><strong>Supabase</strong> — hosts our database, authentication, and account storage.</li>
              <li><strong>Google (Gemini API)</strong> — processes photos you submit to the material scanner, to identify materials in the image.</li>
              <li><strong>Stripe</strong> — processes subscription payments made on the ScrapLab website.</li>
              <li><strong>Apple &amp; RevenueCat</strong> — process and manage subscription purchases made inside the iOS app; RevenueCat receives your subscription/entitlement status, not your payment details.</li>
            </ul>
            <p>We do not share kid profile information (name, age) with any of these providers beyond what&rsquo;s needed to operate the app for your account, and never for advertising or marketing purposes. We may also disclose information if required by law, or to protect the rights, safety, or property of ScrapLab or our users.</p>
          </Section>

          <Section title="Children's privacy">
            <p>ScrapLab is directed at parents and caregivers, not at children, and we do not knowingly collect personal information directly from children. Kid profile information (a first name and age) is provided by the parent or caregiver operating the account, is used solely to personalize recommendations within that account, and is never used for advertising or shared with third parties for their own purposes.</p>
            <p>If you believe a child has provided us with personal information directly, please contact us using the details below and we will delete it.</p>
          </Section>

          <Section title="Your choices">
            <p>You can review, edit, or remove kid profiles and household materials at any time from your Profile. You can cancel your subscription at any time — through the Stripe billing portal on the web, or through your Apple ID subscription settings on iOS.</p>
            <p>To request a copy of your data, or to delete your account and associated data, contact us at the email below. We will act on deletion requests within a reasonable time, except where we need to retain limited information as required by law (for example, payment records).</p>
          </Section>

          <Section title="Data retention">
            <p>We retain your account information for as long as your account is active. If you delete your account, we delete your kid profiles, saved materials, and build history within a reasonable time, other than information we&rsquo;re required to keep for legal, security, or fraud-prevention purposes.</p>
          </Section>

          <Section title="Security">
            <p>We use industry-standard safeguards (including encryption in transit) to protect your information. No method of transmission or storage is 100% secure, but we work to protect your information and will notify you as required by law if we become aware of a breach affecting your account.</p>
          </Section>

          <Section title="Changes to this policy">
            <p>We may update this policy from time to time. If we make material changes, we&rsquo;ll update the effective date above and, where appropriate, notify you directly.</p>
          </Section>

          <Section title="Contact us">
            <p>Questions about this policy, or a request to access or delete your data? Email us at{" "}
              <a href="mailto:privacy@scraplab.app" className="text-builder-500 font-semibold">privacy@scraplab.app</a>.
            </p>
          </Section>
        </div>
      </div>
    </AppShell>
  );
}
