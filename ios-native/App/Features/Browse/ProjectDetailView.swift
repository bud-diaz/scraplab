import Foundation
import ScrapLabModels
import SwiftUI

struct ProjectDetailView: View {
    let idOrSlug: String
    @Bindable var entitlements: EntitlementsStore
    let onStartBuild: (UUID) -> Void
    @State private var store: ProjectDetailStore

    init(idOrSlug: String, baseURL: URL, session: SessionStore, entitlements: EntitlementsStore, onStartBuild: @escaping (UUID) -> Void) {
        self.idOrSlug = idOrSlug
        self.entitlements = entitlements
        self.onStartBuild = onStartBuild
        _store = State(initialValue: ProjectDetailStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        content
            .navigationTitle("Project")
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
            SLEmptyState(title: "Project not found", message: "This project may have been removed.", systemImage: "questionmark.folder")
        case .failed(let message):
            SLEmptyState(title: "Couldn't load project", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.load(idOrSlug: idOrSlug) }
            }
        case .loaded(let project):
            ScrollView {
                VStack(alignment: .leading, spacing: SLSpacing.x5) {
                    header(for: project)
                    if EntitlementGate.isPremiumContentLocked(premium: project.premiumOnly, plan: currentPlan) {
                        UpgradeCard(title: "This project is Plus-only", message: "Upgrade to ScrapLab Plus to see the full build steps.") {}
                    } else {
                        Text(project.description).font(SLFont.body).foregroundStyle(SLColor.bodyText)
                        if let checklist = store.checklist {
                            MaterialsChecklistView(checklist: checklist) { store.toggle($0) }
                        }
                        if !project.safetyNotes.isEmpty {
                            safetySection(for: project)
                        }
                        Button("Start Build") { onStartBuild(project.id) }
                            .buttonStyle(.scrapLab())
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
    private func header(for project: ProjectWithMaterials) -> some View {
        let theme = ProjectDisplayTheme.theme(for: project.slug)
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            HStack(spacing: SLSpacing.x3) {
                Text(theme.emoji).font(.system(size: 40))
                Text(project.title).font(SLFont.title)
            }
            HStack(spacing: SLSpacing.x2) {
                MetadataChip(label: "\(project.timeMinutes) min", systemImage: "clock")
                MetadataChip(label: project.difficulty.rawValue.capitalized)
                MetadataChip(label: "Ages \(project.ageMin)-\(project.ageMax)")
                SupervisionBadge(level: project.supervisionLevel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func safetySection(for project: ProjectWithMaterials) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text("Safety notes").font(SLFont.headline).foregroundStyle(SLColor.ink)
            ForEach(project.safetyNotes, id: \.self) { note in
                Label(note, systemImage: "exclamationmark.triangle").font(SLFont.callout).foregroundStyle(SLColor.coralText)
            }
        }
    }
}
