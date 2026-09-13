import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum LibrarySubTab: String, CaseIterable {
    case saved = "Saved"
    case history = "History"
    case collections = "Collections"
}

enum LibraryPhase: Equatable {
    case loading
    case loaded
    case failed(message: String)
}

/// Ports `/library`: both lists load in parallel on appear, and any failure shows a retry
/// banner rather than rendering an empty state (a network error is not the same thing as
/// "you have nothing saved yet").
@MainActor @Observable
final class LibraryStore {
    private(set) var savedProjects: [SavedProject] = []
    private(set) var buildHistory: [BuildHistory] = []
    private(set) var phase: LibraryPhase = .loading
    var selectedTab: LibrarySubTab = .saved

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func loadIfNeeded() async {
        guard phase == .loading, savedProjects.isEmpty, buildHistory.isEmpty else { return }
        await reload()
    }

    func reload() async {
        phase = .loading
        guard let token = await session.currentAccessToken() else {
            savedProjects = []
            buildHistory = []
            phase = .loaded
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            async let savedResponse: SavedProjectsResponse = client.send(Endpoints.savedProjects)
            async let historyResponse: BuildHistoryResponse = client.send(Endpoints.buildHistory)
            let (saved, history) = try await (savedResponse, historyResponse)
            savedProjects = saved.savedProjects
            buildHistory = history.buildHistory
            phase = .loaded
        } catch {
            phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong loading your library.")
        }
    }

    func unsave(_ saved: SavedProject) async {
        guard let token = await session.currentAccessToken() else { return }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        savedProjects.removeAll { $0.id == saved.id }
        do {
            let _: EmptyResponse = try await client.send(Endpoints.deleteSavedProject(saved.id))
        } catch {
            // Restore on failure rather than leaving the UI silently out of sync.
            if !savedProjects.contains(where: { $0.id == saved.id }) {
                savedProjects.append(saved)
            }
        }
    }
}
