import Foundation

public enum HTTPMethod: String, Codable, Sendable { case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE" }

public enum ActivityQueryDifficulty: String, Codable, CaseIterable, Sendable { case easy, medium, hard, adaptive }
public enum ActivityQueryEnergyLevel: String, Codable, CaseIterable, Sendable { case calm, moderate, active, chaoticGoblin = "chaotic-goblin" }

public struct ActivitiesQuery: Equatable, Sendable {
    public var category: String?
    public var difficulty: ActivityQueryDifficulty?
    public var ageRange: String?
    public var timeMax: Int?
    public var energyLevel: ActivityQueryEnergyLevel?
    public var scrapTag: String?
    public var search: String?
    public var premium: Bool?
    public var featured: Bool?
    public var limit: Int?
    public var offset: Int?

    public init(category: String? = nil, difficulty: ActivityQueryDifficulty? = nil, ageRange: String? = nil, timeMax: Int? = nil, energyLevel: ActivityQueryEnergyLevel? = nil, scrapTag: String? = nil, search: String? = nil, premium: Bool? = nil, featured: Bool? = nil, limit: Int? = nil, offset: Int? = nil) {
        self.category = category; self.difficulty = difficulty; self.ageRange = ageRange; self.timeMax = timeMax; self.energyLevel = energyLevel; self.scrapTag = scrapTag; self.search = search; self.premium = premium; self.featured = featured; self.limit = limit; self.offset = offset
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.appendIfPresent("category", category)
        items.appendIfPresent("difficulty", difficulty?.rawValue)
        items.appendIfPresent("age_range", ageRange)
        items.appendIfPresent("time_max", timeMax.map(String.init))
        items.appendIfPresent("energy_level", energyLevel?.rawValue)
        items.appendIfPresent("scrap_tag", scrapTag)
        items.appendIfPresent("search", search)
        items.appendIfPresent("premium", premium.map { $0 ? "true" : "false" })
        items.appendIfPresent("featured", featured.map { $0 ? "true" : "false" })
        items.appendIfPresent("limit", limit.map(String.init))
        items.appendIfPresent("offset", offset.map(String.init))
        return items
    }
}

public struct ProjectsQuery: Equatable, Sendable {
    public var age: Int?
    public var materialIDs: [UUID]
    public var time: Int?
    public var cleanupLevel: String?
    public var supervisionLevel: String?
    public var difficulty: String?

    public init(age: Int? = nil, materialIDs: [UUID] = [], time: Int? = nil, cleanupLevel: String? = nil, supervisionLevel: String? = nil, difficulty: String? = nil) {
        self.age = age; self.materialIDs = materialIDs; self.time = time; self.cleanupLevel = cleanupLevel; self.supervisionLevel = supervisionLevel; self.difficulty = difficulty
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.appendIfPresent("age", age.map(String.init))
        if !materialIDs.isEmpty { items.append(URLQueryItem(name: "materials", value: materialIDs.map(\.uuidString).joined(separator: ","))) }
        items.appendIfPresent("time", time.map(String.init))
        items.appendIfPresent("cleanup_level", cleanupLevel)
        items.appendIfPresent("supervision_level", supervisionLevel)
        items.appendIfPresent("difficulty", difficulty)
        return items
    }
}

public struct MaterialsQuery: Equatable, Sendable {
    public var category: String?
    public init(category: String? = nil) { self.category = category }
    var queryItems: [URLQueryItem] { category.map { [URLQueryItem(name: "category", value: $0)] } ?? [] }
}

private extension Array where Element == URLQueryItem {
    mutating func appendIfPresent(_ name: String, _ value: String?) {
        guard let value, !value.isEmpty else { return }
        append(URLQueryItem(name: name, value: value))
    }
}

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
    public static func activities(_ query: ActivitiesQuery) -> Endpoint { Endpoint(path: "/api/activities", method: .get, queryItems: query.queryItems) }
    /// The backend resolves this route param by either UUID `id` or `slug`, so deep links
    /// like `/explore/<slug>` can hit it directly without a client-side slug-to-id lookup.
    public static func activity(_ idOrSlug: String) -> Endpoint { Endpoint(path: "/api/activities/\(idOrSlug)", method: .get) }
    public static func activity(_ id: UUID) -> Endpoint { activity(id.uuidString) }
    public static let projects = Endpoint(path: "/api/projects", method: .get)
    public static func projects(_ query: ProjectsQuery) -> Endpoint { Endpoint(path: "/api/projects", method: .get, queryItems: query.queryItems) }
    /// Same slug-or-id resolution as `activity(_:)`, per `resolveProject` on the backend.
    public static func project(_ idOrSlug: String) -> Endpoint { Endpoint(path: "/api/projects/\(idOrSlug)", method: .get) }
    public static func project(_ id: UUID) -> Endpoint { project(id.uuidString) }
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
    public static func materials(_ query: MaterialsQuery) -> Endpoint { Endpoint(path: "/api/materials", method: .get, queryItems: query.queryItems) }

    public static let childProfiles = Endpoint(path: "/api/child-profiles", method: .get)
    public static let createChildProfile = Endpoint(path: "/api/child-profiles", method: .post)
    public static func updateChildProfile(_ id: UUID) -> Endpoint { Endpoint(path: "/api/child-profiles/\(id.uuidString)", method: .patch) }
    public static func deleteChildProfile(_ id: UUID) -> Endpoint { Endpoint(path: "/api/child-profiles/\(id.uuidString)", method: .delete) }
}
