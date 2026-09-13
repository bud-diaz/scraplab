import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum BrowsePhase: Equatable {
    case idle
    case loading
    case loadingMore
    case loaded
    case failed(message: String)
}

/// Owns the Browse tab's activity list: the pure `BrowseCatalogPageState` decides what the
/// next request looks like, this class owns the network call and the loaded results.
@MainActor @Observable
final class BrowseStore {
    private(set) var activities: [Activity] = []
    private(set) var phase: BrowsePhase = .idle

    var filters = BrowseCatalogFilters() {
        didSet {
            guard filters != oldValue else { return }
            page.replaceFilters(filters)
            scheduleReload()
        }
    }

    private var page = BrowseCatalogPageState()
    private var reloadTask: Task<Void, Never>?
    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func loadInitialPageIfNeeded() async {
        guard phase == .idle else { return }
        await load(resetting: true)
    }

    func retry() async {
        await load(resetting: true)
    }

    func loadMoreIfNeeded(after activity: Activity) async {
        guard activity.id == activities.last?.id, page.canLoadMore, phase == .loaded else { return }
        await load(resetting: false)
    }

    /// Debounces filter/search changes so a fast typist does not fire a request per keystroke.
    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.load(resetting: true)
        }
    }

    private func load(resetting: Bool) async {
        phase = resetting ? .loading : .loadingMore
        let token = await session.currentAccessToken()
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: ActivitiesResponse = try await client.send(Endpoints.activities(page.currentQuery()))
            activities = resetting ? response.activities : activities + response.activities
            page.markLoaded(total: response.total)
            _ = page.advancePageIfPossible()
            phase = .loaded
        } catch {
            phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong loading activities.")
        }
    }
}
