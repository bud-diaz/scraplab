import Foundation
import ScrapLabModels
import SwiftUI

struct MysteryBuildView: View {
    @Bindable var router: AppRouter
    @State private var store: MysteryBuildStore

    init(baseURL: URL, session: SessionStore, router: AppRouter) {
        self.router = router
        _store = State(initialValue: MysteryBuildStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        content
            .navigationTitle("Mystery Build")
            .navigationBarTitleDisplayMode(.inline)
            .background(SLColor.pageBackground)
            .task { await store.reroll() }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            VStack(spacing: SLSpacing.x3) {
                ProgressView()
                Text("Picking your mystery materials…").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .planGate(let message):
            UpgradeCard(title: "Mystery Build", message: message) {
                router.presentedSheet = .upgrade
            }
            .padding(SLSpacing.x4)
        case .failed(let message):
            SLEmptyState(title: "Couldn't roll materials", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.reroll() }
            }
        case .loaded(let materials):
            ScrollView {
                VStack(spacing: SLSpacing.x5) {
                    materialsGrid(materials)
                    ageControl
                    HStack(spacing: SLSpacing.x3) {
                        Button("Re-roll") { Task { await store.reroll() } }
                            .buttonStyle(.scrapLab(.secondary))
                        // A plain Button, not a NavigationLink: this needs to switch to the
                        // Create tab and replace its path, not push within Profile's own
                        // stack, since `profilePath`/`createPath` are independently typed
                        // per-tab arrays (same reasoning as `RootTabView.startBuild`).
                        Button("Find Builds →") {
                            router.selectedTab = .create
                            router.createPath = [.results(materialIDs: materials.map(\.id), childAge: store.childAge)]
                        }
                        .buttonStyle(.scrapLab())
                    }
                }
                .padding(SLSpacing.x4)
            }
        }
    }

    private func materialsGrid(_ materials: [MysteryMaterial]) -> some View {
        HStack(spacing: SLSpacing.x3) {
            ForEach(materials, id: \.id) { material in
                VStack(spacing: SLSpacing.x2) {
                    Text(material.icon ?? "📦").font(.system(size: 32))
                    Text(material.name).font(SLFont.callout).foregroundStyle(SLColor.ink).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(SLSpacing.x3)
                .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
                .slShadow()
            }
        }
    }

    private var ageControl: some View {
        Stepper("Child's age: \(store.childAge) yrs", value: $store.childAge, in: CreateAge.pickerRange)
    }
}
