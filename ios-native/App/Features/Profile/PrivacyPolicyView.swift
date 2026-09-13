import SwiftUI

/// Ports `src/app/privacy/page.tsx` verbatim — this is legal copy, not something to
/// paraphrase. Keep this in sync with the web page if that page's text changes; the
/// effective date is a plain constant there too, updated only when the policy's
/// substance changes, not on every deploy.
struct PrivacyPolicyView: View {
    private static let effectiveDate = "September 5, 2026"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x2) {
                Text("Effective \(Self.effectiveDate)").font(SLFont.caption).foregroundStyle(SLColor.mutedText)

                paragraph("ScrapLab (\u{201c}ScrapLab,\u{201d} \u{201c}we,\u{201d} \u{201c}us\u{201d}) helps parents and caregivers turn household materials into safe, age-appropriate build projects for kids. This policy explains what information we collect when you use the ScrapLab app or website, why we collect it, and the choices you have. ScrapLab is built for and used by parents and caregivers — not by children directly.")

                section("Information we collect") {
                    paragraph("**Account information.** When you create a ScrapLab account, we collect your email address and password (handled by our authentication provider, Supabase — we never see or store your password in plain text).")
                    paragraph("**Kid profiles.** If you add a profile for your child, we store the first name (optional) and age you enter, so recommendations can be filtered to what's age-appropriate. This information is entered by you, the parent or caregiver — ScrapLab does not collect any information directly from children.")
                    paragraph("**Materials and build activity.** We store the materials you select or scan, your saved \u{201c}household staples,\u{201d} the projects you save, and your build history (which projects you started or completed, and which kid profile you built them for), so ScrapLab can give you better recommendations over time.")
                    paragraph("**Photos for material scanning.** If you use the photo scanner (a ScrapLab Plus feature), the photo you take is sent to our AI vision provider to detect which materials are visible, and the result is returned to your device. We do not save a copy of the photo — it is processed to produce a list of detected materials and then discarded. Photos of household materials are the intended use of this feature; please don't include photos of people, including children, when using the scanner.")
                    paragraph("**Subscription and payment information.** If you subscribe to ScrapLab Plus, payment is handled entirely by Apple (via In-App Purchase, on iOS) or Stripe (on the web) — ScrapLab never receives or stores your card number. We do store your subscription status (e.g. \u{201c}Plus\u{201d} or \u{201c}Free\u{201d}) so the app knows which features to unlock.")
                    paragraph("**Usage information.** Standard technical information (like error logs) may be collected automatically to keep ScrapLab reliable and secure.")
                }

                section("How we use your information") {
                    paragraph("We use the information above to: generate and personalize build recommendations; remember your household's materials and kid profiles between visits; manage your account and subscription; keep the service safe and reliable; and communicate with you about your account (for example, a receipt or a support reply).")
                    paragraph("We do not use your information, or your child's information, to serve targeted or behavioral advertising, and we do not sell personal information.")
                }

                section("Who we share information with") {
                    paragraph("We work with a small number of service providers who process data on our behalf, under their own privacy and security commitments:")
                    bullet("**Supabase** — hosts our database, authentication, and account storage.")
                    bullet("**Google (Gemini API)** — processes photos you submit to the material scanner, to identify materials in the image.")
                    bullet("**Stripe** — processes subscription payments made on the ScrapLab website.")
                    bullet("**Apple & RevenueCat** — process and manage subscription purchases made inside the iOS app; RevenueCat receives your subscription/entitlement status, not your payment details.")
                    paragraph("We do not share kid profile information (name, age) with any of these providers beyond what's needed to operate the app for your account, and never for advertising or marketing purposes. We may also disclose information if required by law, or to protect the rights, safety, or property of ScrapLab or our users.")
                }

                section("Children's privacy") {
                    paragraph("ScrapLab is directed at parents and caregivers, not at children, and we do not knowingly collect personal information directly from children. Kid profile information (a first name and age) is provided by the parent or caregiver operating the account, is used solely to personalize recommendations within that account, and is never used for advertising or shared with third parties for their own purposes.")
                    paragraph("If you believe a child has provided us with personal information directly, please contact us using the details below and we will delete it.")
                }

                section("Your choices") {
                    paragraph("You can review, edit, or remove kid profiles and household materials at any time from your Profile. You can cancel your subscription at any time — through the Stripe billing portal on the web, or through your Apple ID subscription settings on iOS.")
                    paragraph("You can permanently delete your account at any time from Profile → Delete Account. This immediately removes your kid profiles, saved projects, and build history, and cancels an active web (Stripe) subscription automatically. Deleting your account does not cancel an Apple subscription — cancel that separately from your Apple ID subscription settings, or you'll continue to be billed by Apple. If you'd rather we delete your account for you, or you want a copy of your data first, contact us at the email below. We will act on any request within a reasonable time, except where we need to retain limited information as required by law (for example, payment records).")
                }

                section("Data retention") {
                    paragraph("We retain your account information for as long as your account is active. If you delete your account, we delete your kid profiles, saved materials, and build history within a reasonable time, other than information we're required to keep for legal, security, or fraud-prevention purposes.")
                }

                section("Security") {
                    paragraph("We use industry-standard safeguards (including encryption in transit) to protect your information. No method of transmission or storage is 100% secure, but we work to protect your information and will notify you as required by law if we become aware of a breach affecting your account.")
                }

                section("Changes to this policy") {
                    paragraph("We may update this policy from time to time. If we make material changes, we'll update the effective date above and, where appropriate, notify you directly.")
                }

                section("Contact us") {
                    paragraph("Questions about this policy, or a request to access or delete your data? Email us at privacy@scraplab.app.")
                }
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .background(SLColor.pageBackground)
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text(title).font(SLFont.headline).foregroundStyle(SLColor.ink)
            content()
        }
        .padding(.top, SLSpacing.x3)
    }

    private func paragraph(_ text: String) -> some View {
        Text(LocalizedStringKey(text)).font(SLFont.callout).foregroundStyle(SLColor.bodyText)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: SLSpacing.x2) {
            Text("•").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            paragraph(text)
        }
    }
}
