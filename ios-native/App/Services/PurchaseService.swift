import Foundation

struct PlusOffering: Equatable, Sendable {
    let priceDisplay: String
}

enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
}

enum PurchaseServiceError: Error, LocalizedError, Equatable {
    case unconfigured

    var errorDescription: String? {
        "In-app purchases are not configured in this build yet."
    }
}

/// Boundary a future RevenueCat adapter implements. Deliberately mirrors
/// `AuthSessionAdapter`/`EntitlementsLoading` in `Services/`: the store below is written
/// and testable-by-inspection against this protocol today, and swapping in the real
/// `RevenueCat` SPM package later is a one-file change with no call-site edits.
///
/// Adding that real package cannot happen here: SwiftPM dependency resolution needs
/// network access this environment doesn't have for third-party packages, and RevenueCat's
/// SDK is Apple-platform-only, so it also can't be verified by the Linux `ScrapLabCore`
/// package the way `ScrapLabAPI`/`ScrapLabModels` are. `Purchases.configure`, the App Store
/// Connect subscription product, and the RevenueCat dashboard entitlement all have to be
/// set up from Xcode/App Store Connect before this boundary can be implemented for real.
protocol PurchaseServicing: Sendable {
    /// Called once per sign-in with the Supabase user id, per the plan's fix for the
    /// RevenueCat identity bug: `Purchases.configure` anonymously at launch, then
    /// `logIn(supabaseUserId)` on every sign-in rather than reusing a stale app user id.
    func configure(appUserID: String) async
    func currentOffering() async throws -> PlusOffering?
    func purchasePlus() async throws -> PurchaseOutcome
    /// Returns whether the `plus` entitlement is active after restoring.
    func restorePurchases() async throws -> Bool
    func managementURL() async throws -> URL?
    func logOut() async
}

struct UnconfiguredPurchaseService: PurchaseServicing {
    func configure(appUserID: String) async {}
    func currentOffering() async throws -> PlusOffering? { nil }
    func purchasePlus() async throws -> PurchaseOutcome { throw PurchaseServiceError.unconfigured }
    func restorePurchases() async throws -> Bool { throw PurchaseServiceError.unconfigured }
    func managementURL() async throws -> URL? { nil }
    func logOut() async {}
}
