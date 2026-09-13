import SwiftUI

struct RootTabView: View {
    @Bindable var router: AppRouter
    @Bindable var session: SessionStore
    @Bindable var entitlements: EntitlementsStore
    @State private var browseStore: BrowseStore
    @State private var libraryStore: LibraryStore

    init(router: AppRouter, session: SessionStore, entitlements: EntitlementsStore) {
        self.router = router
        self.session = session
        self.entitlements = entitlements
        _browseStore = State(initialValue: BrowseStore(baseURL: AppEnvironment.apiBaseURL, session: session))
        _libraryStore = State(initialValue: LibraryStore(baseURL: AppEnvironment.apiBaseURL, session: session))
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            homeTab.tabItem { Label("Home", systemImage: "house") }.tag(AppTab.home)
            createTab.tabItem { Label("Create", systemImage: "plus.circle") }.tag(AppTab.create)
            buildLogTab.tabItem { Label("Build Log", systemImage: "book.closed") }.tag(AppTab.buildLog)
            browseTab.tabItem { Label("Browse", systemImage: "safari") }.tag(AppTab.browse)
            profileTab.tabItem { Label("Profile", systemImage: "person") }.tag(AppTab.profile)
        }
        .tint(SLColor.primary)
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(sheet)
                .presentationCornerRadius(SLRadius.sheetTop)
                .presentationBackground(SLColor.pageBackground)
        }
    }

    private var homeTab: some View {
        NavigationStack(path: $router.homePath) {
            HomeView(router: router, session: session, baseURL: AppEnvironment.apiBaseURL)
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route { case .foundation: FoundationDemoView(entitlements: entitlements) }
                }
        }
    }

    private var createTab: some View {
        NavigationStack(path: $router.createPath) {
            CreateMethodListView()
                .navigationDestination(for: CreateRoute.self) { route in
                    switch route {
                    case .manual:
                        ManualMaterialPickerView(baseURL: AppEnvironment.apiBaseURL)
                    case .scan:
                        ScanView(baseURL: AppEnvironment.apiBaseURL, session: session, router: router)
                    case .results(let materialIDs, let childAge):
                        CreateResultsView(materialIDs: materialIDs, childAge: childAge, baseURL: AppEnvironment.apiBaseURL, session: session)
                    case .activity(let slug):
                        ActivityDetailView(idOrSlug: slug, baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements)
                    }
                }
        }
    }

    private var buildLogTab: some View {
        NavigationStack(path: $router.buildLogPath) {
            Group {
                if session.isAuthenticated {
                    LibraryView(store: libraryStore, router: router)
                } else {
                    GuestSignInNudge(title: "Build Log", message: "Sign in to save and resume builds.") { router.presentedSheet = .signIn }
                }
            }
            .navigationDestination(for: BuildLogRoute.self) { route in
                switch route {
                case .project(let id):
                    ProjectDetailView(idOrSlug: id.uuidString, baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements, onStartBuild: startBuild)
                case .build(let id):
                    BuildPlayerView(idOrSlug: id.uuidString, baseURL: AppEnvironment.apiBaseURL, session: session, router: router)
                case .complete(let projectId):
                    BuildCompleteView(projectID: projectId, baseURL: AppEnvironment.apiBaseURL, session: session, router: router)
                }
            }
        }
    }

    private var browseTab: some View {
        NavigationStack(path: $router.browsePath) {
            BrowseListView(store: browseStore)
                .navigationDestination(for: BrowseRoute.self) { route in
                    switch route {
                    case .explore(let slug):
                        ActivityDetailView(idOrSlug: slug, baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements)
                    case .project(let id):
                        ProjectDetailView(idOrSlug: id.uuidString, baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements, onStartBuild: startBuild)
                    }
                }
        }
    }

    /// Matches the `scraplab://build/<uuid>` deep link's own behavior: starting a build
    /// always lands in the Build Log tab, whether the user tapped "Start Build" from
    /// Browse or from a saved project in the Library itself.
    private func startBuild(projectID: UUID) {
        router.selectedTab = .buildLog
        router.buildLogPath = [.build(projectID)]
    }

    private var profileTab: some View {
        NavigationStack(path: $router.profilePath) {
            Group {
                if session.isAuthenticated {
                    ProfileView(baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements, router: router)
                } else {
                    GuestSignInNudge(title: "Profile", message: "Sign in to manage your household and plan.") { router.presentedSheet = .signIn }
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .subscription:
                    SubscriptionView(baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements)
                case .mysteryBuild:
                    MysteryBuildView(baseURL: AppEnvironment.apiBaseURL, session: session, router: router)
                case .challenges:
                    ChallengesView(router: router)
                case .privacyPolicy:
                    PrivacyPolicyView()
                }
            }
        }
    }

    @ViewBuilder private func sheetView(_ sheet: AppSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .signIn:
                SLEmptyState(title: "Sign in", message: "Authentication is ready for a Supabase adapter; no session is simulated.", systemImage: "person.crop.circle", actionTitle: "Not now") { router.cancelAuthentication() }
            case .upgrade:
                SubscriptionView(baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Close") { router.presentedSheet = nil } }
                    }
            case .authCallback:
                SLEmptyState(title: "Confirming account", message: "The callback was received. Supabase session exchange will be connected next.", systemImage: "envelope.badge")
            }
        }
    }
}
