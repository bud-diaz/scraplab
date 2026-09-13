import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

/// Owns the build step player's lifecycle, ported from `src/app/build/[id]/page.tsx`.
/// `idOrSlug` is a **project** id/slug — the build_history row is a separate id
/// (`buildId`) created lazily the first time a signed-in user opens the player, via
/// `start_or_resume_build` on the server (safe to call repeatedly; it resumes rather
/// than duplicating). Guests never persist: `buildId` stays nil and every step change
/// is purely local, matching the web's guest behavior exactly.
@MainActor @Observable
final class BuildPlayerStore {
    private(set) var phase: DetailPhase<ProjectWithMaterials> = .loading
    private(set) var stepState = BuildStepPlayerState(totalSteps: 0)
    private(set) var completionError: String?
    private(set) var buildId: UUID?

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func load(idOrSlug: String) async {
        guard RouteSegment.isValidProjectLookup(idOrSlug) else {
            phase = .notFound
            return
        }
        phase = .loading
        let token = await session.currentAccessToken()
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: ProjectResponse = try await client.send(Endpoints.project(idOrSlug))
            let project = response.project
            stepState = BuildStepPlayerState(totalSteps: project.instructions.count)
            phase = .loaded(project)
            if token != nil {
                await startOrResumeBuild(projectID: project.id, token: token)
            }
        } catch {
            if case APIError.notFound = error {
                phase = .notFound
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong loading this build.")
            }
        }
    }

    private func startOrResumeBuild(projectID: UUID, token: String?) async {
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: BuildEntryResponse = try await client.send(Endpoints.createBuildHistory, body: StartBuildRequest(projectId: projectID))
            buildId = response.buildEntry.id
            stepState = BuildStepPlayerState(totalSteps: stepState.totalSteps, currentStep: response.buildEntry.currentStep)
        } catch {
            // Matches the web: a failed start/resume leaves the player fully usable
            // locally, just unpersisted, rather than blocking the build.
        }
    }

    func goToStep(_ index: Int) {
        guard index >= 0, index < stepState.totalSteps else { return }
        stepState = BuildStepPlayerState(totalSteps: stepState.totalSteps, currentStep: index)
        reportProgress(UpdateBuildProgressRequest(currentStep: index))
    }

    func advance() {
        stepState.advance()
        reportProgress(UpdateBuildProgressRequest(currentStep: stepState.currentStep))
    }

    func retreat() {
        stepState.retreat()
        reportProgress(UpdateBuildProgressRequest(currentStep: stepState.currentStep))
    }

    /// Fires the abandon PATCH without blocking navigation, matching the web's Pause link.
    func pause() {
        reportProgress(UpdateBuildProgressRequest(completionStatus: .abandoned))
    }

    /// Awaited, unlike step navigation: the caller needs to know whether to route to the
    /// completion screen or show an inline retry error.
    func complete() async -> Bool {
        guard let buildId else { return true }
        let token = await session.currentAccessToken()
        guard token != nil else { return true }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let _: BuildEntryResponse = try await client.send(
                Endpoints.updateBuildHistory(buildId),
                body: UpdateBuildProgressRequest(completionStatus: .completed, currentStep: stepState.currentStep)
            )
            completionError = nil
            return true
        } catch {
            completionError = "Couldn't save your completion — try again."
            return false
        }
    }

    /// Fire-and-forget: the web ignores step-progress PATCH failures too, since losing a
    /// single progress write is not worth blocking the child's build.
    private func reportProgress(_ body: UpdateBuildProgressRequest) {
        guard let buildId else { return }
        Task { [weak self] in
            guard let self, let token = await self.session.currentAccessToken() else { return }
            let client = APIClient(baseURL: self.baseURL, tokenProvider: { token })
            _ = try? await client.send(Endpoints.updateBuildHistory(buildId), body: body, as: BuildEntryResponse.self)
        }
    }
}
