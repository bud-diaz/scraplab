import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum HouseholdStaplesPhase: Equatable {
    case loading
    case loaded
    case failed(message: String)
}

/// `POST /api/household-inventory` is an upsert keyed on `(user_id, material_id)`, so
/// toggling a staple just re-POSTs with the flipped `stapleFlag` rather than needing the
/// household_inventory row's own id — matching the web's `StaplesSection` exactly.
@MainActor @Observable
final class HouseholdStaplesStore {
    private(set) var inventory: [HouseholdInventory] = []
    private(set) var allMaterials: [Material] = []
    private(set) var phase: HouseholdStaplesPhase = .loading
    private(set) var actionError: String?

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    var staples: [HouseholdInventory] { inventory.filter(\.stapleFlag) }

    /// Materials not already tracked in household inventory, for the "add a staple" picker.
    var addableMaterials: [Material] {
        let trackedIDs = Set(inventory.map(\.materialId))
        return allMaterials.filter { !trackedIDs.contains($0.id) }
    }

    func loadIfNeeded() async {
        guard phase == .loading, inventory.isEmpty else { return }
        await reload()
    }

    func reload() async {
        phase = .loading
        guard let token = await session.currentAccessToken() else {
            inventory = []
            phase = .loaded
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            async let inventoryResponse: HouseholdInventoryResponse = client.send(Endpoints.inventory)
            async let materialsResponse: MaterialsResponse = client.send(Endpoints.materials)
            let (loadedInventory, loadedMaterials) = try await (inventoryResponse, materialsResponse)
            inventory = loadedInventory.inventory
            allMaterials = loadedMaterials.materials
            phase = .loaded
        } catch {
            phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Couldn't load household staples.")
        }
    }

    func setStaple(materialID: UUID, isStaple: Bool) async {
        actionError = nil
        guard let token = await session.currentAccessToken() else {
            actionError = "Sign in to manage household staples."
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        let request = HouseholdInventoryRequest(materialId: materialID, source: .saved, stapleFlag: isStaple)
        do {
            let response: HouseholdInventoryItemResponse = try await client.send(Endpoints.createInventoryItem, body: request)
            if let index = inventory.firstIndex(where: { $0.materialId == materialID }) {
                inventory[index] = response.item
            } else {
                inventory.append(response.item)
            }
        } catch {
            if case APIError.planGate(_, let message, _) = error {
                actionError = message ?? "Household staples require ScrapLab Plus."
            } else {
                actionError = (error as? LocalizedError)?.errorDescription ?? "Couldn't update this staple."
            }
        }
    }
}
