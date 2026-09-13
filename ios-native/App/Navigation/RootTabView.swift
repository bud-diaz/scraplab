import SwiftUI

struct RootTabView: View {
    @Bindable var router: AppRouter
    @Bindable var session: SessionStore
    @Bindable var entitlements: EntitlementsStore
    @State private var browseStore: BrowseStore

    init(router: AppRouter, session: SessionStore, entitlements: EntitlementsStore) {
        self.router = router
        self.session = session
        self.entitlements = entitlements
        _browseStore = State(initialValue: BrowseStore(baseURL: AppEnvironment.apiBaseURL, session: session))
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
            VStack(spacing: SLSpacing.x6) {
                Image(systemName: "hammer.fill").font(.system(size: 44)).foregroundStyle(SLColor.primary)
                Text("Make something from what you have.").font(SLFont.title).multilineTextAlignment(.center)
                Text("Browse freely as a guest, or connect an account when you want to save your work.")
                    .font(SLFont.body).foregroundStyle(SLColor.bodyText).multilineTextAlignment(.center)
                Button("Open foundation demo") { router.homePath.append(.foundation) }
                    .buttonStyle(.scrapLab(.secondary))
            }
            .padding(SLSpacing.x6)
            .navigationTitle("ScrapLab")
            .background(SLColor.pageBackground.ignoresSafeArea())
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
                    PlaceholderDestination(title: "Build Log", message: "Your builds will appear here when the API is connected.")
                } else {
                    GuestSignInNudge(title: "Build Log", message: "Sign in to save and resume builds.") { router.presentedSheet = .signIn }
                }
            }
            .navigationDestination(for: BuildLogRoute.self) { route in
                switch route {
                case .project: PlaceholderDestination(title: "Project", message: "Project details are not connected yet.")
                case .build: PlaceholderDestination(title: "Build", message: "The build player is not connected yet.")
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
                        ProjectDetailView(idOrSlug: id.uuidString, baseURL: AppEnvironment.apiBaseURL, session: session, entitlements: entitlements)
                    }
                }
        }
    }

    private var profileTab: some View {
        NavigationStack(path: $router.profilePath) {
            Group {
                if session.isAuthenticated {
                    PlaceholderDestination(title: "Profile", message: "Profile settings are not connected yet.")
                } else {
                    GuestSignInNudge(title: "Profile", message: "Sign in to manage your household and plan.") { router.presentedSheet = .signIn }
                }
            }
            .navigationDestination(for: ProfileRoute.self) { _ in
                PlaceholderDestination(title: "Settings", message: "Settings are not connected yet.")
            }
        }
    }

    @ViewBuilder private func sheetView(_ sheet: AppSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .signIn:
                SLEmptyState(title: "Sign in", message: "Authentication is ready for a Supabase adapter; no session is simulated.", systemImage: "person.crop.circle", actionTitle: "Not now") { router.cancelAuthentication() }
            case .upgrade:
                UpgradeCard(title: "ScrapLab Plus", message: "Purchases will be connected through the entitlements boundary.") { router.presentedSheet = nil }
                    .padding()
            case .authCallback:
                SLEmptyState(title: "Confirming account", message: "The callback was received. Supabase session exchange will be connected next.", systemImage: "envelope.badge")
            }
        }
    }
}
