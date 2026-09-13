import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum SaveToLibraryPhase: Equatable {
    case idle
    case saving
    case saved
    case failed(message: String)
}

@MainActor @Observable
final class BuildCompleteStore {
    private(set) var phase: DetailPhase<ProjectWithMaterials> = .loading
    private(set) var saveState: SaveToLibraryPhase = .idle

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func load(projectID: UUID) async {
        phase = .loading
        let token = await session.currentAccessToken()
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: ProjectResponse = try await client.send(Endpoints.project(projectID))
            phase = .loaded(response.project)
        } catch {
            if case APIError.notFound = error {
                phase = .notFound
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
            }
        }
    }

    /// Mirrors `CompleteBuildActions`: a project can only be saved while signed in, since
    /// `POST /api/saved-projects` requires auth. A 409 means it was already saved, which
    /// the web treats as success rather than an error.
    func save(projectID: UUID) async {
        guard let token = await session.currentAccessToken() else {
            saveState = .failed(message: "Sign in to save this to your library.")
            return
        }
        saveState = .saving
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let _: SavedProjectResponse = try await client.send(Endpoints.saveProject, body: SaveProjectRequest(projectId: projectID))
            saveState = .saved
        } catch {
            if case APIError.conflict = error {
                saveState = .saved
            } else if case APIError.limitReached(let message, _) = error {
                saveState = .failed(message: message ?? "You've reached your saved-project limit. Upgrade to ScrapLab Plus for more room.")
            } else if case APIError.unauthorized = error {
                saveState = .failed(message: "Sign in to save this to your library.")
            } else {
                saveState = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Couldn't save this project.")
            }
        }
    }
}
