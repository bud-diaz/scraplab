import SwiftUI

@main
struct ScrapLabApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var router: AppRouter
    @State private var session: SessionStore
    @State private var entitlements: EntitlementsStore
    private let purchaseService: any PurchaseServicing

    init() {
        SLFontRegistrar.registerBundledFonts()
        _router = State(initialValue: AppRouter())
        _session = State(initialValue: SessionStore())
        _entitlements = State(initialValue: EntitlementsStore(loader: ScrapLabAccessLoader()))
        purchaseService = UnconfiguredPurchaseService()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(router: router, session: session, entitlements: entitlements)
                .preferredColorScheme(.light)
                .task {
                    await session.restore()
                    await refreshEntitlementsForCurrentSession()
                }
                .onOpenURL { router.open($0, isAuthenticated: session.isAuthenticated) }
                .onChange(of: session.isAuthenticated) { _, authenticated in
                    if authenticated {
                        router.replayPendingLinkAfterAuthentication()
                        Task { await refreshEntitlementsForCurrentSession() }
                        if case .authenticated(let user) = session.phase {
                            Task { await purchaseService.configure(appUserID: user.id.uuidString) }
                        }
                    } else {
                        entitlements.reset()
                        Task { await purchaseService.logOut() }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await refreshEntitlementsForCurrentSession() }
                }
        }
    }

    private func refreshEntitlementsForCurrentSession() async {
        if let token = await session.currentAccessToken() {
            await entitlements.refresh(accessToken: token)
        }
    }
}
