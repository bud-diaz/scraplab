import Foundation
import ScrapLabAPI
import SwiftUI

/// Ports `DeleteAccountSection`: an inline warning card behind a confirm step, no separate
/// modal and no typed confirmation text. `DELETE /api/me/delete-account` needs only the
/// auth header — deleting the Supabase user cascades to child_profiles/saved_projects/
/// build_history/household_inventory via FK, so there is nothing else to call here.
struct DeleteAccountSectionView: View {
    @Bindable var session: SessionStore
    @Bindable var entitlements: EntitlementsStore
    let baseURL: URL

    @State private var isConfirming = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var isPlus: Bool {
        if case .loaded(let snapshot) = entitlements.phase, snapshot.plan == .plus { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            if isConfirming {
                Text("This permanently deletes your account, kid profiles, saved projects, and build history.")
                    .font(SLFont.callout)
                    .foregroundStyle(SLColor.bodyText)
                if isPlus {
                    Text("This does not cancel an active Apple subscription — cancel that separately from your Apple ID subscription settings, or you'll continue to be billed.")
                        .font(SLFont.caption)
                        .foregroundStyle(SLColor.coralText)
                }
                if let errorMessage {
                    Text(errorMessage).font(SLFont.caption).foregroundStyle(SLColor.coralText)
                }
                if isDeleting {
                    ProgressView()
                } else {
                    HStack(spacing: SLSpacing.x3) {
                        Button("Yes, delete my account") { Task { await delete() } }
                            .buttonStyle(.scrapLab(.destructive))
                        Button("Cancel") { isConfirming = false }
                            .buttonStyle(.scrapLab(.secondary))
                    }
                }
            } else {
                Button("Delete Account") { isConfirming = true }
                    .font(SLFont.callout)
                    .foregroundStyle(SLColor.coralText)
            }
        }
        .padding(SLSpacing.x4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
    }

    private func delete() async {
        isDeleting = true
        errorMessage = nil
        guard let token = await session.currentAccessToken() else {
            errorMessage = "Sign in again to delete your account."
            isDeleting = false
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let _: EmptyResponse = try await client.send(Endpoints.deleteAccount)
            await session.signOut()
        } catch {
            errorMessage = "Could not delete account. Please try again."
        }
        isDeleting = false
    }
}
