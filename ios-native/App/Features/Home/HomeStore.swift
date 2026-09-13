import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

/// Assembles every section of Home. Per the plan's own risk note, "Suggested For You"
/// intentionally calls `GET /api/activities?featured=true&limit=10` instead of porting
/// `src/lib/mock-data.ts` — the web's version is content debt the plan explicitly says
/// not to carry over. `ContinueBuilding`/`WeeklyProgress`/`HouseholdStaples` stay empty
/// for guests, matching the web sections that simply don't fetch without a session.
@MainActor @Observable
final class HomeStore {
    private(set) var featuredActivities: [Activity] = []
    private(set) var isLoadingFeatured = false
    private(set) var buildHistory: [BuildHistory] = []
    private(set) var householdInventory: [HouseholdInventory] = []

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    var weeklyProgress: WeeklyProgressSummary { WeeklyProgressSummary(buildHistory: buildHistory) }
    var continueBuilding: [BuildHistory] { ContinueBuildingSelector.recentInProgress(buildHistory) }
    var staples: [HouseholdInventory] { HouseholdStaplesSelector.staples(householdInventory) }

    func loadIfNeeded() async {
        async let featured: Void = loadFeaturedIfNeeded()
        async let history: Void = loadBuildHistory()
        async let inventory: Void = loadHouseholdInventory()
        _ = await (featured, history, inventory)
    }

    private func loadFeaturedIfNeeded() async {
        guard featuredActivities.isEmpty, !isLoadingFeatured else { return }
        isLoadingFeatured = true
        defer { isLoadingFeatured = false }
        let client = APIClient(baseURL: baseURL)
        let query = ActivitiesQuery(featured: true, limit: 10)
        if let response = try? await client.send(Endpoints.activities(query), as: ActivitiesResponse.self) {
            featuredActivities = response.activities
        }
    }

    private func loadBuildHistory() async {
        guard let token = await session.currentAccessToken() else { return }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        if let response = try? await client.send(Endpoints.buildHistory, as: BuildHistoryResponse.self) {
            buildHistory = response.buildHistory
        }
    }

    private func loadHouseholdInventory() async {
        guard let token = await session.currentAccessToken() else { return }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        if let response = try? await client.send(Endpoints.inventory, as: HouseholdInventoryResponse.self) {
            householdInventory = response.inventory
        }
    }
}
