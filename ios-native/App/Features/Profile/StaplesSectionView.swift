import Foundation
import ScrapLabModels
import SwiftUI

struct StaplesSectionView: View {
    @Bindable var store: HouseholdStaplesStore
    @State private var isAddingStaple = false

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            HStack {
                Text("Household Staples").font(SLFont.headline).foregroundStyle(SLColor.ink)
                Spacer()
                Button {
                    isAddingStaple = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .font(SLFont.callout.weight(.semibold))
                .foregroundStyle(SLColor.primaryPressed)
            }

            if let actionError = store.actionError {
                Text(actionError).font(SLFont.caption).foregroundStyle(SLColor.coralText)
            }

            switch store.phase {
            case .loading:
                ProgressView()
            case .failed(let message):
                Text(message).font(SLFont.callout).foregroundStyle(SLColor.coralText)
            case .loaded:
                if store.staples.isEmpty {
                    Text("Mark materials you always have on hand so builds can use them automatically.")
                        .font(SLFont.callout).foregroundStyle(SLColor.bodyText)
                } else {
                    ForEach(store.staples, id: \.id) { item in
                        HStack {
                            Text(item.material?.icon ?? "📦")
                            Text(item.material?.name ?? "Material").font(SLFont.body).foregroundStyle(SLColor.ink)
                            Spacer()
                            Button {
                                Task { await store.setStaple(materialID: item.materialId, isStaple: false) }
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(SLColor.mutedText)
                            }
                        }
                    }
                }
            }
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
        .sheet(isPresented: $isAddingStaple) {
            AddStapleSheet(materials: store.addableMaterials) { material in
                Task { await store.setStaple(materialID: material.id, isStaple: true) }
            }
        }
    }
}

private struct AddStapleSheet: View {
    let materials: [ScrapLabModels.Material]
    let onPick: (ScrapLabModels.Material) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List(filteredMaterials, id: \.id) { material in
                Button {
                    onPick(material)
                    dismiss()
                } label: {
                    HStack {
                        Text(material.icon ?? "📦")
                        Text(material.name).foregroundStyle(SLColor.ink)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search materials")
            .navigationTitle("Add Staple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private var filteredMaterials: [ScrapLabModels.Material] {
        guard !search.isEmpty else { return materials }
        return materials.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
}
