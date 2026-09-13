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

/// Boundary implemented by `RevenueCatPurchaseService` in configured builds and
/// `UnconfiguredPurchaseService` when local runtime keys are absent. The app keeps
/// purchase UI and server sync decoupled from the SDK so tests and non-Xcode checks can
/// still exercise the native billing flow without touching StoreKit.
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
