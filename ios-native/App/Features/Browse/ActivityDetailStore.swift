import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

@MainActor @Observable
final class ActivityDetailStore {
    private(set) var phase: DetailPhase<Activity> = .loading
    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func load(idOrSlug: String) async {
        guard RouteSegment.isSafeActivityLookup(idOrSlug) else {
            phase = .notFound
            return
        }
        phase = .loading
        let token = await session.currentAccessToken()
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: ActivityResponse = try await client.send(Endpoints.activity(idOrSlug))
            phase = .loaded(response.activity)
        } catch {
            if case APIError.notFound = error {
                phase = .notFound
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong loading this activity.")
            }
        }
    }
}
