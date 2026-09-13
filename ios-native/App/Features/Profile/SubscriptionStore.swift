import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum SubscriptionActionPhase: Equatable {
    case idle
    case purchasing
    case restoring
    case syncing
    case failed(message: String)
}

/// Owns the native purchase flow. `/api/me/sync-revenuecat` never trusts the client's
/// purchase result (it re-verifies against RevenueCat's own API), so every action here
/// ends by calling it rather than optimistically flipping local plan state.
@MainActor @Observable
final class SubscriptionStore {
    private(set) var offering: PlusOffering?
    private(set) var actionPhase: SubscriptionActionPhase = .idle

    private let purchaseService: any PurchaseServicing
    private let baseURL: URL
    private let session: SessionStore
    private let entitlements: EntitlementsStore

    init(purchaseService: any PurchaseServicing = UnconfiguredPurchaseService(), baseURL: URL, session: SessionStore, entitlements: EntitlementsStore) {
        self.purchaseService = purchaseService
        self.baseURL = baseURL
        self.session = session
        self.entitlements = entitlements
    }

    func loadOffering() async {
        offering = try? await purchaseService.currentOffering()
    }

    func purchase() async {
        actionPhase = .purchasing
        do {
            _ = try await purchaseService.purchasePlus()
            await syncEntitlement()
        } catch {
            actionPhase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Purchase failed. Try again.")
        }
    }

    func restore() async {
        actionPhase = .restoring
        do {
            _ = try await purchaseService.restorePurchases()
            await syncEntitlement()
        } catch {
            actionPhase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Restore failed. Try again.")
        }
    }

    func openManagement() async -> URL? {
        try? await purchaseService.managementURL()
    }

    private func syncEntitlement() async {
        actionPhase = .syncing
        guard let token = await session.currentAccessToken() else {
            actionPhase = .failed(message: "Sign in to sync your subscription.")
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let _: SyncRevenueCatResponse = try await client.send(Endpoints.syncRevenueCat, as: SyncRevenueCatResponse.self)
            actionPhase = .idle
            await entitlements.refresh(accessToken: token)
        } catch {
            actionPhase = .failed(message: "Purchase completed, but syncing your plan failed. Pull to refresh.")
        }
    }
}
