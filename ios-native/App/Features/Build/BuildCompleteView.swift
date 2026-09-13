import Foundation
import ScrapLabModels
import SwiftUI

struct BuildCompleteView: View {
    let projectID: UUID
    @Bindable var session: SessionStore
    @Bindable var router: AppRouter
    @State private var store: BuildCompleteStore

    init(projectID: UUID, baseURL: URL, session: SessionStore, router: AppRouter) {
        self.projectID = projectID
        self.session = session
        self.router = router
        _store = State(initialValue: BuildCompleteStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        content
            .navigationBarBackButtonHidden(true)
            .background(SLColor.pageBackground)
            .task { await store.load(projectID: projectID) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .notFound, .failed:
            SLEmptyState(title: "Built it. Nice.", message: "We couldn't reload the project details, but your build is saved.", systemImage: "party.popper")
                .overlay(alignment: .bottom) { actions(title: "Your project") }
        case .loaded(let project):
            celebration(project: project)
        }
    }

    private func celebration(project: ProjectWithMaterials) -> some View {
        VStack(spacing: 0) {
            ZStack {
                SLColor.hero.ignoresSafeArea(edges: .top)
                confetti
                VStack(spacing: SLSpacing.x3) {
                    Text(ProjectDisplayTheme.theme(for: project.slug).emoji)
                        .font(.system(size: 44))
                        .frame(width: 88, height: 88)
                        .background(.white, in: Circle())
                    Text("Built it. Nice.").font(SLFont.largeTitle).foregroundStyle(.white)
                    Text(project.title).font(SLFont.title2).foregroundStyle(.white.opacity(0.9))
                }
                .padding(SLSpacing.x8)
            }
            .frame(height: 280)

            actions(title: nil)
                .padding(.top, SLSpacing.x6)
                .background(SLColor.pageBackground, in: RoundedRectangle(cornerRadius: SLRadius.sheetTop))
                .offset(y: -SLRadius.sheetTop)
        }
    }

    /// Static celebratory dots — the web has no confetti animation library either, just
    /// fixed-position CSS dots.
    private var confetti: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(SLColor.sunshine.opacity(0.6 + Double(index % 3) * 0.15))
                    .frame(width: 10, height: 10)
                    .offset(x: CGFloat((index * 47) % 220) - 110, y: CGFloat((index * 31) % 160) - 80)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func actions(title: String?) -> some View {
        VStack(spacing: SLSpacing.x3) {
            if let title { Text(title).font(SLFont.headline) }

            if session.isAuthenticated {
                switch store.saveState {
                case .saved:
                    Label("Saved to Library ✓", systemImage: "checkmark.circle.fill")
                        .font(SLFont.callout).foregroundStyle(SLColor.leafText)
                case .failed(let message):
                    VStack(spacing: SLSpacing.x2) {
                        Text(message).font(SLFont.caption).foregroundStyle(SLColor.coralText)
                        saveButton
                    }
                case .saving:
                    ProgressView()
                case .idle:
                    saveButton
                }
            } else {
                Button("Go to Library") {
                    router.selectedTab = .buildLog
                    router.buildLogPath = []
                }
                .buttonStyle(.scrapLab())
            }

            Button("Build Something Else") {
                router.selectedTab = .create
                router.createPath = [.manual]
            }
            .buttonStyle(.scrapLab(.secondary))
        }
        .padding(SLSpacing.x4)
    }

    private var saveButton: some View {
        Button("Save to Library") {
            Task { await store.save(projectID: projectID) }
        }
        .buttonStyle(.scrapLab())
    }
}
