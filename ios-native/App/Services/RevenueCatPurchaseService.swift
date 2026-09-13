import Foundation
import RevenueCat

struct RevenueCatPurchaseService: PurchaseServicing {
    private static let plusEntitlementID = "plus"
    private let apiKey: String
    private let managementURLValue = URL(string: "https://apps.apple.com/account/subscriptions")

    init(apiKey: String) {
        self.apiKey = apiKey
        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: apiKey)
        }
    }

    func configure(appUserID: String) async {
        guard Purchases.isConfigured else { return }
        do {
            if Purchases.shared.appUserID != appUserID {
                _ = try await Purchases.shared.logIn(appUserID)
            }
        } catch {
            // The server sync remains authoritative; keep the app usable and surface
            // purchase/restore failures from the explicit user actions instead.
        }
    }

    func currentOffering() async throws -> PlusOffering? {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.monthly ?? offerings.current?.availablePackages.first else {
            return nil
        }
        return PlusOffering(priceDisplay: package.localizedPriceString)
    }

    func purchasePlus() async throws -> PurchaseOutcome {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.monthly ?? offerings.current?.availablePackages.first else {
            throw RevenueCatPurchaseServiceError.missingOffering
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled { return .cancelled }
        return .purchased
    }

    func restorePurchases() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        return info.entitlements[Self.plusEntitlementID]?.isActive == true
    }

    func managementURL() async throws -> URL? {
        managementURLValue
    }

    func logOut() async {
        guard Purchases.isConfigured, !Purchases.shared.isAnonymous else { return }
        _ = try? await Purchases.shared.logOut()
    }
}

enum RevenueCatPurchaseServiceError: Error, LocalizedError, Equatable {
    case missingOffering

    var errorDescription: String? {
        switch self {
        case .missingOffering:
            "ScrapLab Plus is not available from RevenueCat yet. Check the offering and subscription product setup."
        }
    }
}
