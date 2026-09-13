import SwiftUI

struct FoundationDemoView: View {
    @Bindable var entitlements: EntitlementsStore
    @State private var token = ""

    var body: some View {
        Form {
            Section("Authenticated API") {
                SecureField("Supabase access token", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .privacySensitive()
                Button("Load /api/me/access") {
                    let suppliedToken = token
                    Task { await entitlements.refresh(accessToken: suppliedToken) }
                }
                .buttonStyle(.scrapLab())
                .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }

            Section("Response") {
                response
            }
        }
        .scrollContentBackground(.hidden)
        .background(SLColor.pageBackground)
        .navigationTitle("Foundation Demo")
    }

    private var isLoading: Bool {
        if case .loading = entitlements.phase { return true }
        return false
    }

    @ViewBuilder private var response: some View {
        switch entitlements.phase {
        case .idle:
            Text("Supply a real access token to call the authenticated endpoint.")
                .foregroundStyle(SLColor.bodyText)
        case .loading:
            HStack { ProgressView(); Text("Loading access…") }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(SLColor.coralText)
        case .loaded(let access):
            LabeledContent("Plan", value: access.plan.rawValue.capitalized)
            LabeledContent("Recommendations today", value: "\(access.usage.recommendationsToday)")
                .font(SLFont.tabular(16))
            LabeledContent("Photo scan", value: access.limits.photoScan ? "Available" : "Unavailable")
            optionalLimit("Daily recommendation limit", access.limits.dailyRecommendations)
            optionalLimit("Child profiles", access.limits.childProfiles)
            optionalLimit("Saved projects", access.limits.savedProjects)
        }
    }

    private func optionalLimit(_ title: String, _ value: Int?) -> some View {
        LabeledContent(title, value: value.map(String.init) ?? "Unlimited")
            .font(SLFont.tabular(16))
    }
}

#Preview {
    NavigationStack { FoundationDemoView(entitlements: EntitlementsStore()) }
}
