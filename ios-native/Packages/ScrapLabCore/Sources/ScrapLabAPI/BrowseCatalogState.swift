import Foundation
import ScrapLabModels

public enum BrowseTimeFilter: Int, Codable, CaseIterable, Sendable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60
}

public struct BrowseCatalogFilters: Equatable, Sendable {
    public var searchText: String
    public var category: ActivityCategory?
    public var difficulty: ActivityQueryDifficulty?
    public var ageRange: ActivityAgeRange?
    public var timeLimit: BrowseTimeFilter?
    public var energyLevel: ActivityQueryEnergyLevel?
    public var scrapTag: String?
    public var premium: Bool?
    public var featured: Bool?

    public init(
        searchText: String = "",
        category: ActivityCategory? = nil,
        difficulty: ActivityQueryDifficulty? = nil,
        ageRange: ActivityAgeRange? = nil,
        timeLimit: BrowseTimeFilter? = nil,
        energyLevel: ActivityQueryEnergyLevel? = nil,
        scrapTag: String? = nil,
        premium: Bool? = nil,
        featured: Bool? = nil
    ) {
        self.searchText = searchText
        self.category = category
        self.difficulty = difficulty
        self.ageRange = ageRange
        self.timeLimit = timeLimit
        self.energyLevel = energyLevel
        self.scrapTag = scrapTag
        self.premium = premium
        self.featured = featured
    }

    public var hasActiveFilters: Bool {
        normalizedSearch != nil || category != nil || difficulty != nil || ageRange != nil || timeLimit != nil || energyLevel != nil || normalizedScrapTag != nil || premium != nil || featured != nil
    }

    public var normalizedSearch: String? { searchText.trimmedNonEmpty }
    public var normalizedScrapTag: String? { scrapTag?.trimmedNonEmpty }

    public func query(limit: Int = 50, offset: Int = 0) -> ActivitiesQuery {
        ActivitiesQuery(
            category: category?.rawValue,
            difficulty: difficulty,
            ageRange: ageRange?.rawValue,
            timeMax: timeLimit?.rawValue,
            energyLevel: energyLevel,
            scrapTag: normalizedScrapTag,
            search: normalizedSearch,
            premium: premium,
            featured: featured,
            limit: limit,
            offset: offset
        )
    }

    public mutating func clear() {
        self = BrowseCatalogFilters()
    }
}

public struct BrowseCatalogPageState: Equatable, Sendable {
    public var filters: BrowseCatalogFilters
    public var limit: Int
    public private(set) var offset: Int
    public private(set) var total: Int?

    public init(filters: BrowseCatalogFilters = BrowseCatalogFilters(), limit: Int = 50, offset: Int = 0, total: Int? = nil) {
        self.filters = filters
        self.limit = max(1, limit)
        self.offset = max(0, offset)
        self.total = total
    }

    public var canLoadMore: Bool {
        guard let total else { return true }
        return offset + limit < total
    }

    public func currentQuery() -> ActivitiesQuery {
        filters.query(limit: limit, offset: offset)
    }

    public mutating func replaceFilters(_ newFilters: BrowseCatalogFilters) {
        filters = newFilters
        offset = 0
        total = nil
    }

    public mutating func markLoaded(total: Int) {
        self.total = max(0, total)
    }

    public mutating func advancePageIfPossible() -> Bool {
        guard canLoadMore else { return false }
        offset += limit
        return true
    }
}

public struct ProjectCatalogFilters: Equatable, Sendable {
    public var age: Int?
    public var materialIDs: [UUID]
    public var timeLimitMinutes: Int?
    public var cleanupLevel: CleanupLevel?
    public var supervisionLevel: SupervisionLevel?
    public var difficulty: Difficulty?

    public init(age: Int? = nil, materialIDs: [UUID] = [], timeLimitMinutes: Int? = nil, cleanupLevel: CleanupLevel? = nil, supervisionLevel: SupervisionLevel? = nil, difficulty: Difficulty? = nil) {
        self.age = age
        self.materialIDs = materialIDs
        self.timeLimitMinutes = timeLimitMinutes
        self.cleanupLevel = cleanupLevel
        self.supervisionLevel = supervisionLevel
        self.difficulty = difficulty
    }

    public func query() -> ProjectsQuery {
        ProjectsQuery(
            age: age,
            materialIDs: materialIDs,
            time: timeLimitMinutes,
            cleanupLevel: cleanupLevel?.rawValue,
            supervisionLevel: supervisionLevel?.rawValue,
            difficulty: difficulty?.rawValue
        )
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
