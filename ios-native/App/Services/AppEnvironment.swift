import Foundation

/// Single source of truth for runtime configuration and backend URLs.
enum AppEnvironment {
    static let apiBaseURL = URL(string: "https://scraplab-inky.vercel.app")!

    static var supabaseURL: URL? {
        plistURL(forKey: "ScrapLabSupabaseURL")
    }

    static var supabaseAnonKey: String? {
        plistString(forKey: "ScrapLabSupabaseAnonKey")
    }

    static var revenueCatAPIKey: String? {
        plistString(forKey: "ScrapLabRevenueCatIOSAPIKey")
    }

    static var authAdapter: any AppAuthSessionAdapter {
        guard let supabaseURL, let supabaseAnonKey else { return UnconfiguredAuthSessionAdapter() }
        return SupabaseAuthSessionAdapter(supabaseURL: supabaseURL, anonKey: supabaseAnonKey)
    }

    static var purchaseService: any PurchaseServicing {
        guard let revenueCatAPIKey else { return UnconfiguredPurchaseService() }
        return RevenueCatPurchaseService(apiKey: revenueCatAPIKey)
    }

    private static func plistURL(forKey key: String) -> URL? {
        guard let raw = plistString(forKey: key) else { return nil }
        return URL(string: raw)
    }

    private static func plistString(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
        return trimmed
    }
}
