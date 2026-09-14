import Foundation
import ScrapLabModels
import SwiftUI

/// `ActivityMatch` is keyed today via `\.activity.id` (a `String`), not `Identifiable` —
/// wraps it so it satisfies `SwipeableCardCarousel`'s `Item: Identifiable` constraint.
private struct MatchCarouselItem: Identifiable {
    let match: ActivityMatch
    var id: String { match.activity.id }
}

/// `AiSuggestion` (Gemini output) has no natural id — the existing grid keyed it by array
/// index (`\.offset`); this wraps that same index for the carousel's `Identifiable` need.
private struct SuggestionCarouselItem: Identifiable {
    let suggestion: AiSuggestion
    let index: Int
    var id: Int { index }
}

struct CreateResultsView: View {
    let materialIDs: [UUID]
    let childAge: Int
    @State private var store: CreateResultsStore

    init(materialIDs: [UUID], childAge: Int, baseURL: URL, session: SessionStore) {
        self.materialIDs = materialIDs
        self.childAge = childAge
        _store = State(initialValue: CreateResultsStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(SLColor.pageBackground)
            .task { await store.load(materialIDs: materialIDs, childAge: childAge) }
    }

    private var title: String {
        store.phase == .loading ? "Finding builds…" : "Here's what you can build"
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ProgressView("Finding builds…").frame(maxWidth: .infinity, maxHeight: .infinity)
        case .limitReached(let message):
            SLEmptyState(title: "Daily limit reached", message: message, systemImage: "sparkles")
        case .planGate(let message):
            ScrollView {
                UpgradeCard(title: "ScrapLab Plus", message: message) {}
                    .padding(SLSpacing.x4)
            }
        case .offline(let message):
            SLEmptyState(title: "Couldn't find builds", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.load(materialIDs: materialIDs, childAge: childAge) }
            }
        case .failed(let message):
            SLEmptyState(title: "Couldn't find builds", message: message, systemImage: "exclamationmark.triangle", actionTitle: "Try again") {
                Task { await store.load(materialIDs: materialIDs, childAge: childAge) }
            }
        case .loaded:
            if store.matches.isEmpty && store.aiSuggestions.isEmpty {
                SLEmptyState(title: "Not quite enough yet", message: "Add a few more materials and we'll find the perfect build for you.", systemImage: "wrench.and.screwdriver")
            } else {
                resultsList
            }
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x5) {
                filterChips
                if !store.filteredMatches.isEmpty {
                    SwipeableCardCarousel(items: store.filteredMatches.map(MatchCarouselItem.init)) { item, _ in
                        NavigationLink(value: CreateRoute.activity(slug: item.match.activity.slug)) {
                            ProjectCardView(activity: item.match.activity, matchLabel: item.match.matchLabel, layout: .full)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, SLSpacing.x4)
                }

                if !store.aiSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: SLSpacing.x3) {
                        HStack(spacing: SLSpacing.x2) {
                            Text("AI-Generated Ideas").font(SLFont.headline).foregroundStyle(SLColor.ink)
                            Text("via Gemini").font(SLFont.caption).foregroundStyle(SLColor.mutedText)
                        }
                        .padding(.horizontal, SLSpacing.x4)
                        SwipeableCardCarousel(
                            items: store.aiSuggestions.enumerated().map { SuggestionCarouselItem(suggestion: $1, index: $0) }
                        ) { item, _ in
                            AiSuggestionCardView(suggestion: item.suggestion, index: item.index)
                        }
                        .padding(.horizontal, SLSpacing.x4)
                    }
                }
            }
            .padding(.vertical, SLSpacing.x4)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x2) {
                ForEach(CreateResultsFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.title, isSelected: store.filter == filter) { store.filter = filter }
                }
            }
            .padding(.horizontal, SLSpacing.x4)
        }
    }
}
