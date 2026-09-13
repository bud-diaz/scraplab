import ScrapLabModels
import SwiftUI

struct BrowseListView: View {
    @Bindable var store: BrowseStore
    @State private var isPresentingFilters = false

    var body: some View {
        content
            .navigationTitle("Browse")
            .searchable(text: $store.filters.searchText, prompt: "Search activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingFilters = true
                    } label: {
                        Label("Filters", systemImage: store.filters.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $isPresentingFilters) {
                BrowseFilterSheet(filters: $store.filters)
            }
            .task { await store.loadInitialPageIfNeeded() }
            .background(SLColor.pageBackground)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle, .loading:
            ProgressView("Loading activities…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            SLEmptyState(title: "Couldn't load activities", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.retry() }
            }
        case .loaded, .loadingMore:
            if store.activities.isEmpty {
                SLEmptyState(title: "No activities match", message: "Try clearing filters or searching something else.", systemImage: "magnifyingglass")
            } else {
                list
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: SLSpacing.x4) {
                ForEach(store.activities, id: \.id) { activity in
                    NavigationLink(value: BrowseRoute.explore(activity.slug)) {
                        ActivityCardView(activity: activity)
                    }
                    .buttonStyle(.plain)
                    .task { await store.loadMoreIfNeeded(after: activity) }
                }
                if store.phase == .loadingMore {
                    ProgressView().padding()
                }
            }
            .padding(SLSpacing.x4)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}
