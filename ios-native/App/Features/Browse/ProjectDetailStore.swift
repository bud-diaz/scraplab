import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

@MainActor @Observable
final class ProjectDetailStore {
    private(set) var phase: DetailPhase<ProjectWithMaterials> = .loading
    private(set) var checklist: MaterialsChecklistState?
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
            checklist = MaterialsChecklistState.from(response.project)
            phase = .loaded(response.project)
        } catch {
            if case APIError.notFound = error {
                phase = .notFound
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong loading this project.")
            }
        }
    }

    func toggle(_ item: MaterialsChecklistItem) {
        checklist?.toggle(item)
    }
}
