import Foundation

public enum HTTPMethod: String, Codable, Sendable { case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE" }

public struct Endpoint: Equatable, Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]

    public init(path: String, method: HTTPMethod, queryItems: [URLQueryItem] = []) {
        precondition(path.hasPrefix("/api/"), "API endpoint paths must begin with /api/")
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

/// Every route intended for first-party app consumption. Billing checkout,
/// billing portal, and server-to-server webhook routes are deliberately absent.
public enum Endpoints {
    public static let activities = Endpoint(path: "/api/activities", method: .get)
    public static func activity(_ id: UUID) -> Endpoint { Endpoint(path: "/api/activities/\(id.uuidString)", method: .get) }
    public static let projects = Endpoint(path: "/api/projects", method: .get)
    public static func project(_ id: UUID) -> Endpoint { Endpoint(path: "/api/projects/\(id.uuidString)", method: .get) }
    public static let recommendations = Endpoint(path: "/api/recommendations", method: .post)
    public static let activityRecommendations = Endpoint(path: "/api/activity-recommendations", method: .post)

    public static let inventory = Endpoint(path: "/api/household-inventory", method: .get)
    public static let createInventoryItem = Endpoint(path: "/api/household-inventory", method: .post)
    public static func updateInventoryItem(_ id: UUID) -> Endpoint { Endpoint(path: "/api/household-inventory/\(id.uuidString)", method: .patch) }
    public static func deleteInventoryItem(_ id: UUID) -> Endpoint { Endpoint(path: "/api/household-inventory/\(id.uuidString)", method: .delete) }

    public static let access = Endpoint(path: "/api/me/access", method: .get)
    public static let deleteAccount = Endpoint(path: "/api/me/delete-account", method: .delete)
    public static let syncRevenueCat = Endpoint(path: "/api/me/sync-revenuecat", method: .post)

    public static let buildHistory = Endpoint(path: "/api/build-history", method: .get)
    public static let createBuildHistory = Endpoint(path: "/api/build-history", method: .post)
    public static func updateBuildHistory(_ id: UUID) -> Endpoint { Endpoint(path: "/api/build-history/\(id.uuidString)", method: .patch) }

    public static let savedProjects = Endpoint(path: "/api/saved-projects", method: .get)
    public static let saveProject = Endpoint(path: "/api/saved-projects", method: .post)
    public static func deleteSavedProject(_ id: UUID) -> Endpoint { Endpoint(path: "/api/saved-projects/\(id.uuidString)", method: .delete) }

    public static let scanMaterials = Endpoint(path: "/api/scan-materials", method: .post)
    public static let mysteryMaterials = Endpoint(path: "/api/mystery-materials", method: .get)
    public static let materials = Endpoint(path: "/api/materials", method: .get)

    public static let childProfiles = Endpoint(path: "/api/child-profiles", method: .get)
    public static let createChildProfile = Endpoint(path: "/api/child-profiles", method: .post)
    public static func updateChildProfile(_ id: UUID) -> Endpoint { Endpoint(path: "/api/child-profiles/\(id.uuidString)", method: .patch) }
    public static func deleteChildProfile(_ id: UUID) -> Endpoint { Endpoint(path: "/api/child-profiles/\(id.uuidString)", method: .delete) }
}
