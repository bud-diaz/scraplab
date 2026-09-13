import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum CreateResultsPhase: Equatable {
    case loading
    case loaded
    case limitReached(message: String)
    case planGate(message: String)
    case failed(message: String)
}

/// Owns `POST /api/activity-recommendations` for `/create/results`. Guests are allowed
/// here — the route only requires auth to attribute usage to a user instead of an IP,
/// per `getGuestIdentity`/`getUserIdentity` in the route handler — so this attaches a
/// bearer token when one exists but never blocks on `session.isAuthenticated`.
@MainActor @Observable
final class CreateResultsStore {
    private(set) var matches: [ActivityMatch] = []
    private(set) var aiSuggestions: [AiSuggestion] = []
    private(set) var phase: CreateResultsPhase = .loading
    var filter: CreateResultsFilter = .all

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    var filteredMatches: [ActivityMatch] { matches.filter(filter.matches) }

    func load(materialIDs: [UUID], childAge: Int) async {
        phase = .loading
        let token = await session.currentAccessToken()
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        let request = MaterialSelectionState(selectedMaterialIDs: materialIDs).recommendationRequest(childAge: childAge)
        do {
            let response: ActivityRecommendationsResponse = try await client.send(Endpoints.activityRecommendations, body: request)
            matches = response.matches
            aiSuggestions = response.aiSuggestions
            phase = .loaded
        } catch {
            if case APIError.limitReached(let message, _) = error {
                phase = .limitReached(message: message ?? "You've used today's free recommendations. Upgrade to ScrapLab Plus for unlimited builds, or come back tomorrow.")
            } else if case APIError.planGate(_, let message, _) = error {
                phase = .planGate(message: message ?? "This feature requires ScrapLab Plus.")
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong finding builds.")
            }
        }
    }
}
