import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum MysteryBuildPhase: Equatable {
    case loading
    case loaded([MysteryMaterial])
    case planGate(message: String)
    case failed(message: String)
}

@MainActor @Observable
final class MysteryBuildStore {
    private(set) var phase: MysteryBuildPhase = .loading
    var childAge = CreateAge.scanDefault

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func reroll() async {
        phase = .loading
        guard let token = await session.currentAccessToken() else {
            phase = .planGate(message: "Sign in and upgrade to ScrapLab Plus to use Mystery Build.")
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: MysteryMaterialsResponse = try await client.send(Endpoints.mysteryMaterials)
            phase = .loaded(response.materials)
        } catch {
            if case APIError.planGate(_, let message, _) = error {
                phase = .planGate(message: message ?? "Mystery Build requires ScrapLab Plus.")
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Couldn't pick mystery materials.")
            }
        }
    }
}
