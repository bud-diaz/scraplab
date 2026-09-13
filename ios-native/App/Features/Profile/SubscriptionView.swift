import Foundation
import SwiftUI

struct SubscriptionView: View {
    @Bindable var entitlements: EntitlementsStore
    @Environment(\.openURL) private var openURL
    @State private var store: SubscriptionStore

    private static let plusFeatures = [
        "Unlimited daily build recommendations",
        "Photo material scanner",
        "Mystery Build",
        "Household staples",
        "Up to 10 kid profiles",
        "Unlimited saved projects",
        "Priority support",
    ]

    init(baseURL: URL, session: SessionStore, entitlements: EntitlementsStore, purchaseService: any PurchaseServicing = UnconfiguredPurchaseService()) {
        self.entitlements = entitlements
        _store = State(initialValue: SubscriptionStore(purchaseService: purchaseService, baseURL: baseURL, session: session, entitlements: entitlements))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x5) {
                header
                featureList
                if let message = failureMessage {
                    Text(message).font(SLFont.callout).foregroundStyle(SLColor.coralText)
                }
                actions
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("ScrapLab Plus")
        .navigationBarTitleDisplayMode(.inline)
        .background(SLColor.pageBackground)
        .task { await store.loadOffering() }
    }

    private var isPlus: Bool {
        if case .loaded(let snapshot) = entitlements.phase, snapshot.plan == .plus { return true }
        return false
    }

    private var failureMessage: String? {
        if case .failed(let message) = store.actionPhase { return message }
        return nil
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(SLColor.hero)
            if isPlus {
                Text("You're on Plus ✓").font(SLFont.title).foregroundStyle(SLColor.ink)
                Text("Active subscription\(store.offering.map { " · \($0.priceDisplay)" } ?? "")")
                    .font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            } else {
                Text("Upgrade to ScrapLab Plus").font(SLFont.title).foregroundStyle(SLColor.ink)
                Text(store.offering.map { "\($0.priceDisplay) — cancel anytime" } ?? "Unlock the full ScrapLab experience.")
                    .font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            ForEach(Self.plusFeatures, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle.fill")
                    .font(SLFont.callout)
                    .foregroundStyle(SLColor.ink)
            }
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }

    @ViewBuilder
    private var actions: some View {
        switch store.actionPhase {
        case .purchasing, .restoring, .syncing:
            ProgressView().frame(maxWidth: .infinity)
        default:
            if isPlus {
                Button("Manage subscription") {
                    Task {
                        if let url = await store.openManagement() { openURL(url) }
                    }
                }
                .buttonStyle(.scrapLab())
            } else {
                Button("Upgrade to Plus\(store.offering.map { " — \($0.priceDisplay)" } ?? "")") {
                    Task { await store.purchase() }
                }
                .buttonStyle(.scrapLab(.hero))

                Button("Restore purchases") {
                    Task { await store.restore() }
                }
                .buttonStyle(.plain)
                .font(SLFont.caption)
                .foregroundStyle(SLColor.mutedText)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
