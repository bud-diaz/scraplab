import Foundation
import ScrapLabModels
import SwiftUI

struct ActivityDetailView: View {
    let idOrSlug: String
    @Bindable var entitlements: EntitlementsStore
    @State private var store: ActivityDetailStore

    init(idOrSlug: String, baseURL: URL, session: SessionStore, entitlements: EntitlementsStore) {
        self.idOrSlug = idOrSlug
        self.entitlements = entitlements
        _store = State(initialValue: ActivityDetailStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        content
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .background(SLColor.pageBackground)
            .task(id: idOrSlug) { await store.load(idOrSlug: idOrSlug) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ProgressView("Loading…").frame(maxWidth: .infinity, maxHeight: .infinity)
        case .notFound:
            SLEmptyState(title: "Activity not found", message: "This activity may have been removed.", systemImage: "questionmark.folder")
        case .failed(let message):
            SLEmptyState(title: "Couldn't load activity", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.load(idOrSlug: idOrSlug) }
            }
        case .loaded(let activity):
            ScrollView {
                VStack(alignment: .leading, spacing: SLSpacing.x5) {
                    header(for: activity)
                    if EntitlementGate.isPremiumContentLocked(premium: activity.premium, plan: currentPlan) {
                        UpgradeCard(title: "This activity is Plus-only", message: "Upgrade to ScrapLab Plus to see the full instructions.") {}
                    } else {
                        if let description = activity.description {
                            Text(description).font(SLFont.body).foregroundStyle(SLColor.bodyText)
                        }
                        materialsSection(for: activity)
                        if !activity.safetyNotes.isEmpty {
                            safetySection(for: activity)
                        }
                    }
                }
                .padding(SLSpacing.x4)
            }
        }
    }

    private var currentPlan: Plan {
        if case .loaded(let snapshot) = entitlements.phase, snapshot.plan == .plus { return .plus }
        return .free
    }

    @ViewBuilder
    private func header(for activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            HStack(alignment: .top, spacing: SLSpacing.x3) {
                Text(ActivityCategoryTheme.emoji(for: activity.category)).font(.system(size: 40))
                VStack(alignment: .leading, spacing: SLSpacing.x1) {
                    Text(activity.title).font(SLFont.title)
                    if let oneLiner = activity.oneLiner {
                        Text(oneLiner).font(SLFont.body).foregroundStyle(SLColor.bodyText)
                    }
                }
            }
            HStack(spacing: SLSpacing.x2) {
                MetadataChip(label: "\(activity.timeMinutes) min", systemImage: "clock")
                MetadataChip(label: activity.difficulty.rawValue.capitalized)
                SupervisionBadge(level: activity.normalizedSupervisionLevel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func materialsSection(for activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text("Materials").font(SLFont.headline).foregroundStyle(SLColor.ink)
            WrapChips(activity.materialsRequired)
            if !activity.materialsOptional.isEmpty {
                Text("Optional").font(SLFont.caption).foregroundStyle(SLColor.mutedText)
                WrapChips(activity.materialsOptional)
            }
        }
    }

    @ViewBuilder
    private func safetySection(for activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text("Safety notes").font(SLFont.headline).foregroundStyle(SLColor.ink)
            ForEach(activity.safetyNotes, id: \.self) { note in
                Label(note, systemImage: "exclamationmark.triangle").font(SLFont.callout).foregroundStyle(SLColor.coralText)
            }
        }
    }
}

/// A simple flowing chip row. SwiftUI's `Layout` protocol could wrap true rows, but a
/// horizontal scroller is a fine substitute for a materials list that is rarely long.
struct WrapChips: View {
    let labels: [String]
    init(_ labels: [String]) { self.labels = labels }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x2) {
                ForEach(labels, id: \.self) { MetadataChip(label: $0) }
            }
        }
    }
}
