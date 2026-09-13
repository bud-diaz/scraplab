import SwiftUI

struct RootTabView: View {
    @Bindable var router: AppRouter
    @Bindable var session: SessionStore
    @Bindable var entitlements: EntitlementsStore

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
            PlaceholderDestination(title: "Create", message: "Choose materials to begin when the create flow arrives.")
                .navigationDestination(for: CreateRoute.self) { route in
                    switch route {
                    case .manual: PlaceholderDestination(title: "Choose materials", message: "The manual material picker is not connected yet.")
                    case .scan: PlaceholderDestination(title: "Scan materials", message: "Camera and photo selection are not connected yet.")
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
            PlaceholderDestination(title: "Browse", message: "Activities will load here when browse networking is connected.")
                .navigationDestination(for: BrowseRoute.self) { route in
                    switch route {
                    case .explore(let slug): PlaceholderDestination(title: "Explore", message: "Requested activity: \(slug)")
                    case .project: PlaceholderDestination(title: "Project", message: "Project details are not connected yet.")
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
