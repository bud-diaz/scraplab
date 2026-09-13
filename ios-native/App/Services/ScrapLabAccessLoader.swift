import Foundation
import ScrapLabAPI

struct ScrapLabAccessLoader: EntitlementsLoading {
    let baseURL: URL

    init(baseURL: URL = URL(string: "https://scraplab-inky.vercel.app")!) {
        self.baseURL = baseURL
    }

    func accessInfo(accessToken: String) async throws -> EntitlementSnapshot {
        let client = APIClient(baseURL: baseURL, tokenProvider: { accessToken })
        return try await client.send(Endpoints.access)
    }
}
