import Foundation
import ScrapLabModels
import SwiftUI

struct BuildPlayerView: View {
    let idOrSlug: String
    @Bindable var router: AppRouter
    @State private var store: BuildPlayerStore

    init(idOrSlug: String, baseURL: URL, session: SessionStore, router: AppRouter) {
        self.idOrSlug = idOrSlug
        self.router = router
        _store = State(initialValue: BuildPlayerStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .background(SLColor.pageBackground)
            .task { await store.load(idOrSlug: idOrSlug) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .loading:
            ProgressView("Loading…").frame(maxWidth: .infinity, maxHeight: .infinity)
        case .notFound:
            SLEmptyState(title: "Project not found", message: "This build may have been removed.", systemImage: "questionmark.folder")
        case .failed(let message):
            SLEmptyState(title: "Couldn't load this build", message: message, systemImage: "wifi.slash", actionTitle: "Try again") {
                Task { await store.load(idOrSlug: idOrSlug) }
            }
        case .loaded(let project):
            player(for: project)
        }
    }

    private func player(for project: ProjectWithMaterials) -> some View {
        let steps = project.instructions
        let step = steps.indices.contains(store.stepState.currentStep) ? steps[store.stepState.currentStep] : nil

        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: SLSpacing.x5) {
                    progressStepper
                    if let step {
                        stepCard(project: project, step: step)
                    }
                    if let completionError = store.completionError {
                        Text(completionError).font(SLFont.callout).foregroundStyle(SLColor.coralText)
                    }
                }
                .padding(SLSpacing.x4)
            }
            controls(for: project)
        }
        .navigationTitle(project.title)
    }

    private var progressStepper: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            HStack {
                Text("\(store.stepState.progressPercent)% done").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
                Spacer()
                MetadataChip(label: "Step \(store.stepState.currentStep + 1)/\(max(store.stepState.totalSteps, 1))")
            }
            ProgressView(value: Double(store.stepState.progressPercent), total: 100)
                .tint(SLColor.primary)
        }
    }

    private func stepCard(project: ProjectWithMaterials, step: BuildStep) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            ZStack(alignment: .topTrailing) {
                StepIllustrationView(action: StepIllustrationAction(stepTitle: step.instruction))
                if store.stepState.isStepMarkedDone(store.stepState.currentStep) {
                    ZStack {
                        Circle().fill(SLColor.leaf)
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .offset(x: 6, y: -6)
                }
            }
            Text("Step \(step.step)").font(SLFont.caption).foregroundStyle(SLColor.mutedText)
            Text(step.instruction).font(SLFont.title2).foregroundStyle(SLColor.ink)
            if let tip = step.tip {
                Label(tip, systemImage: "lightbulb").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            }
            if let safetyNote = step.safetyNote {
                Label(safetyNote, systemImage: "exclamationmark.triangle").font(SLFont.callout).foregroundStyle(SLColor.coralText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }

    private func controls(for project: ProjectWithMaterials) -> some View {
        VStack(spacing: SLSpacing.x2) {
            HStack(spacing: SLSpacing.x3) {
                Button("Back") { store.retreat() }
                    .buttonStyle(.scrapLab(.secondary))
                    .disabled(store.stepState.isFirstStep)

                if store.stepState.isLastStep {
                    Button("Complete Build") {
                        Task {
                            if await store.complete() {
                                router.buildLogPath.append(.complete(projectId: project.id))
                            }
                        }
                    }
                    .buttonStyle(.scrapLab())
                } else {
                    Button("Mark Done") { store.markCurrentStepDone() }
                        .buttonStyle(.scrapLab())
                }
            }
            Button("Pause Build") {
                store.pause()
                router.buildLogPath = [.project(project.id)]
            }
            .buttonStyle(.plain)
            .font(SLFont.caption)
            .foregroundStyle(SLColor.mutedText)
        }
        .padding(.horizontal, SLSpacing.x4)
        .padding(.top, SLSpacing.x4)
        .padding(.bottom, SLSpacing.x4 + FloatingTabBar.reservedHeight)
        .background(.ultraThinMaterial)
    }
}
