import Foundation
import ScrapLabModels
import SwiftUI

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
        case .failed(let message):
            SLEmptyState(title: "Couldn't find builds", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
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
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SLSpacing.x3) {
                        ForEach(store.filteredMatches, id: \.activity.id) { match in
                            NavigationLink(value: CreateRoute.activity(slug: match.activity.slug)) {
                                ActivityCardView(activity: match.activity, matchLabel: match.matchLabel)
                            }
                            .buttonStyle(.plain)
                        }
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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SLSpacing.x3) {
                            ForEach(Array(store.aiSuggestions.enumerated()), id: \.offset) { index, suggestion in
                                AiSuggestionCardView(suggestion: suggestion, index: index)
                            }
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
