import Foundation
import Observation

enum AppTab: Hashable { case home, create, buildLog, browse, profile }
enum HomeRoute: Hashable { case foundation }
enum CreateRoute: Hashable {
    case manual, scan
    case results(materialIDs: [UUID], childAge: Int)
    /// Pushed from a `CreateResultsView` activity card. A separate case from
    /// `BrowseRoute.explore` because `createPath`/`browsePath` are independently typed
    /// per-tab navigation paths — pushing this keeps the detail screen inside the Create
    /// tab's own stack instead of jumping the user over to Browse mid-flow.
    case activity(slug: String)
}
enum BuildLogRoute: Hashable { case project(UUID), build(UUID) }
enum BrowseRoute: Hashable { case explore(String), project(UUID) }
enum ProfileRoute: Hashable { case settings }
enum AppSheet: Identifiable, Equatable {
    case signIn, upgrade, authCallback
    var id: Self { self }
}

@MainActor @Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath: [HomeRoute] = []
    var createPath: [CreateRoute] = []
    var buildLogPath: [BuildLogRoute] = []
    var browsePath: [BrowseRoute] = []
    var profilePath: [ProfileRoute] = []
    var presentedSheet: AppSheet?
    private(set) var pendingDeepLink: DeepLink?

    func open(_ url: URL, isAuthenticated: Bool) {
        guard let link = DeepLink(url: url) else { return }
        open(link, isAuthenticated: isAuthenticated)
    }

    func open(_ link: DeepLink, isAuthenticated: Bool) {
        guard isAuthenticated || !link.requiresAuthentication else {
            pendingDeepLink = link
            presentedSheet = .signIn
            return
        }
        route(link)
    }

    func replayPendingLinkAfterAuthentication() {
        guard let pendingDeepLink else { return }
        self.pendingDeepLink = nil
        presentedSheet = nil
        route(pendingDeepLink)
    }

    func cancelAuthentication() {
        pendingDeepLink = nil
        presentedSheet = nil
    }

    private func route(_ link: DeepLink) {
        switch link {
        case .explore(let slug):
            selectedTab = .browse
            browsePath = [.explore(slug)]
        case .project(let id):
            selectedTab = .browse
            browsePath = [.project(id)]
        case .build(let id):
            selectedTab = .buildLog
            buildLogPath = [.build(id)]
        case .upgrade:
            presentedSheet = .upgrade
        case .authCallback:
            presentedSheet = .authCallback
        }
    }
}
