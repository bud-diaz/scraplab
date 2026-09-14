import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum MaterialCatalogPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(message: String)
}

/// Owns `GET /api/materials` for the manual picker. The endpoint has no server-side
/// search (only `category`, per `src/app/api/materials/route.ts`), so this loads the
/// full catalog once and lets `MaterialCatalogFilter` do search/category/quick-filter
/// filtering locally. "Recently used" has no backend concept — it's tracked locally in
/// `UserDefaults`, most-recent-first, capped, distinct from the real `HouseholdInventory`
/// staple flag which comes straight from the backend.
@MainActor @Observable
final class ManualMaterialPickerStore {
    private static let recentlyUsedKey = "recentlyUsedMaterialIDs"
    private static let recentlyUsedCap = 20

    private(set) var materials: [Material] = []
    private(set) var phase: MaterialCatalogPhase = .idle
    private(set) var householdInventory: [HouseholdInventory] = []
    var filter = MaterialCatalogFilter()
    var selection = MaterialSelectionState()
    var childAge = 7

    private let baseURL: URL
    private let session: SessionStore
    private let defaults: UserDefaults

    init(baseURL: URL, session: SessionStore, defaults: UserDefaults = .standard) {
        self.baseURL = baseURL
        self.session = session
        self.defaults = defaults
    }

    var categories: [String] { MaterialCatalogFilter.categories(in: materials) }

    var householdStapleIDs: Set<UUID> {
        Set(householdInventory.filter(\.stapleFlag).map(\.materialId))
    }

    var recentlyUsedMaterialIDs: Set<UUID> {
        Set((defaults.stringArray(forKey: Self.recentlyUsedKey) ?? []).compactMap(UUID.init(uuidString:)))
    }

    var filteredMaterials: [Material] {
        filter.apply(to: materials, recentlyUsedIDs: recentlyUsedMaterialIDs, householdStapleIDs: householdStapleIDs)
    }

    func loadIfNeeded() async {
        guard phase == .idle else { return }
        async let materialsLoad: Void = load()
        async let inventoryLoad: Void = loadHouseholdInventory()
        _ = await (materialsLoad, inventoryLoad)
    }

    func retry() async {
        await load()
    }

    /// Wraps `selection.toggle` so a tap that *selects* a material also records it as
    /// recently used; removing a selection doesn't erase its recently-used history.
    func toggleSelection(_ id: UUID) {
        selection.toggle(id)
        if selection.isSelected(id) {
            recordRecentlyUsed(id)
        }
    }

    private func recordRecentlyUsed(_ id: UUID) {
        var ids = defaults.stringArray(forKey: Self.recentlyUsedKey) ?? []
        ids.removeAll { $0 == id.uuidString }
        ids.insert(id.uuidString, at: 0)
        defaults.set(Array(ids.prefix(Self.recentlyUsedCap)), forKey: Self.recentlyUsedKey)
    }

    private func load() async {
        phase = .loading
        let client = APIClient(baseURL: baseURL)
        do {
            let response: MaterialsResponse = try await client.send(Endpoints.materials)
            materials = response.materials
            phase = .loaded
        } catch {
            phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong loading materials.")
        }
    }

    private func loadHouseholdInventory() async {
        guard householdInventory.isEmpty, let token = await session.currentAccessToken() else { return }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        if let response = try? await client.send(Endpoints.inventory, as: HouseholdInventoryResponse.self) {
            householdInventory = response.inventory
        }
    }
}
