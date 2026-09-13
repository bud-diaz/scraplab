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
/// full catalog once and lets `MaterialCatalogFilter` do search/category filtering locally.
@MainActor @Observable
final class ManualMaterialPickerStore {
    private(set) var materials: [Material] = []
    private(set) var phase: MaterialCatalogPhase = .idle
    var filter = MaterialCatalogFilter()
    var selection = MaterialSelectionState()
    var childAge = 7

    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    var categories: [String] { MaterialCatalogFilter.categories(in: materials) }
    var filteredMaterials: [Material] { filter.apply(to: materials) }

    func loadIfNeeded() async {
        guard phase == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
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
}
