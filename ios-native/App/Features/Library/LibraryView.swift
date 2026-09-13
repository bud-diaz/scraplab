import ScrapLabModels
import SwiftUI

struct LibraryView: View {
    @Bindable var store: LibraryStore
    @Bindable var router: AppRouter

    var body: some View {
        VStack(spacing: 0) {
            header
            tabPicker
            content
        }
        .navigationTitle("Library")
        .background(SLColor.pageBackground)
        .task { await store.loadIfNeeded() }
    }

    private var header: some View {
        Text("\(store.savedProjects.count) saved · \(store.buildHistory.count) built")
            .font(SLFont.caption)
            .foregroundStyle(SLColor.mutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SLSpacing.x4)
            .padding(.top, SLSpacing.x2)
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x2) {
                ForEach(LibrarySubTab.allCases, id: \.self) { tab in
                    FilterChip(title: tab.rawValue, isSelected: store.selectedTab == tab) { store.selectedTab = tab }
                }
            }
            .padding(.horizontal, SLSpacing.x4)
        }
        .padding(.vertical, SLSpacing.x3)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            SLEmptyState(title: "Couldn't load your library", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.reload() }
            }
        case .loaded:
            switch store.selectedTab {
            case .saved: savedTab
            case .history: historyTab
            case .collections: SLEmptyState(title: "Collections", message: "Collections are coming soon.", systemImage: "square.stack")
            }
        }
    }

    @ViewBuilder
    private var savedTab: some View {
        if store.savedProjects.isEmpty {
            SLEmptyState(title: "Your workshop shelf is empty", message: "Save a project to find it here later.", systemImage: "shippingbox", actionTitle: "Find a Build") {
                goToManualCreate()
            }
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SLSpacing.x3) {
                    ForEach(store.savedProjects, id: \.id) { saved in
                        if let project = saved.project {
                            ZStack(alignment: .topTrailing) {
                                NavigationLink(value: BuildLogRoute.project(project.id)) {
                                    SavedProjectCardView(project: project)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    Task { await store.unsave(saved) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, SLColor.mutedText)
                                }
                                .padding(SLSpacing.x2)
                            }
                        }
                    }
                }
                .padding(SLSpacing.x4)
            }
        }
    }

    @ViewBuilder
    private var historyTab: some View {
        if store.buildHistory.isEmpty {
            SLEmptyState(title: "Nothing built yet", message: "Let's fix that.", systemImage: "hammer", actionTitle: "Let's fix that") {
                goToManualCreate()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: SLSpacing.x3) {
                    ForEach(store.buildHistory, id: \.id) { entry in
                        BuildHistoryRowView(entry: entry)
                    }
                }
                .padding(SLSpacing.x4)
            }
        }
    }

    private func goToManualCreate() {
        router.selectedTab = .create
        router.createPath = [.manual]
    }
}
