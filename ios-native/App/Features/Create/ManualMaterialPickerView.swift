import ScrapLabModels
import SwiftUI

struct ManualMaterialPickerView: View {
    @Bindable var store: ManualMaterialPickerStore

    init(baseURL: URL) {
        _store = State(initialValue: ManualMaterialPickerStore(baseURL: baseURL))
    }

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: SLSpacing.x3)]

    var body: some View {
        VStack(spacing: 0) {
            content
            if store.phase == .loaded {
                bottomBar
            }
        }
        .navigationTitle("What do you have?")
        .searchable(text: $store.filter.searchText, prompt: "Search materials")
        .background(SLColor.pageBackground)
        .task { await store.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle, .loading:
            ProgressView("Loading materials…").frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            SLEmptyState(title: "Couldn't load materials", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.retry() }
            }
        case .loaded:
            ScrollView {
                VStack(alignment: .leading, spacing: SLSpacing.x4) {
                    if !store.selection.selectedMaterialIDs.isEmpty {
                        selectionTray
                    }
                    categoryChips
                    materialGrid
                }
                .padding(.top, SLSpacing.x3)
                .padding(.bottom, SLSpacing.x16)
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x2) {
                FilterChip(title: "All", isSelected: store.filter.category == nil) { store.filter.category = nil }
                ForEach(store.categories, id: \.self) { category in
                    FilterChip(title: category.replacingOccurrences(of: "-", with: " ").capitalized, isSelected: store.filter.category == category) {
                        store.filter.category = category
                    }
                }
            }
            .padding(.horizontal, SLSpacing.x4)
        }
    }

    private var selectionTray: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x2) {
                ForEach(selectedMaterials, id: \.id) { material in
                    HStack(spacing: SLSpacing.x1) {
                        Text(material.icon ?? "📦")
                        Text(material.name).font(SLFont.caption)
                        Button {
                            store.selection.remove(material.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(SLColor.mutedText)
                        }
                    }
                    .padding(.horizontal, SLSpacing.x3)
                    .padding(.vertical, SLSpacing.x2)
                    .background(SLColor.surface, in: Capsule())
                    .overlay(Capsule().stroke(SLColor.line))
                }
            }
            .padding(.horizontal, SLSpacing.x4)
        }
    }

    private var selectedMaterials: [ScrapLabModels.Material] {
        store.materials.filter { store.selection.isSelected($0.id) }
    }

    private var materialGrid: some View {
        LazyVGrid(columns: columns, spacing: SLSpacing.x3) {
            ForEach(store.filteredMaterials, id: \.id) { material in
                MaterialTileView(material: material, isSelected: store.selection.isSelected(material.id)) {
                    store.selection.toggle(material.id)
                }
            }
        }
        .padding(.horizontal, SLSpacing.x4)
    }

    private var bottomBar: some View {
        VStack(spacing: SLSpacing.x2) {
            HStack {
                Text("Child's age:").font(SLFont.caption).foregroundStyle(SLColor.bodyText)
                Stepper("\(store.childAge) yrs", value: $store.childAge, in: CreateAge.pickerRange)
                    .font(SLFont.callout)
                    .fixedSize()
                Spacer()
            }
            HStack {
                Text(selectionSummary).font(SLFont.caption).foregroundStyle(SLColor.bodyText)
                Spacer()
                NavigationLink(value: CreateRoute.results(materialIDs: store.selection.selectedMaterialIDs, childAge: store.childAge)) {
                    Text("Find Builds")
                }
                .buttonStyle(.scrapLab())
                .disabled(!store.selection.canSubmit)
            }
        }
        .padding(SLSpacing.x4)
        .background(.ultraThinMaterial)
    }

    private var selectionSummary: String {
        let count = store.selection.selectedMaterialIDs.count
        return count == 0 ? "Select at least 1 material" : "\(count) material\(count == 1 ? "" : "s") selected"
    }
}
