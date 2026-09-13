import Foundation
import Testing
@testable import ScrapLabAPI
import ScrapLabModels

@Test func browseCatalogFiltersBuildBackendActivitiesQuery() {
    let filters = BrowseCatalogFilters(
        searchText: "  rocket ship  ",
        category: .engineering,
        difficulty: .hard,
        ageRange: .sixToEight,
        timeLimit: .thirty,
        energyLevel: .active,
        scrapTag: "  cardboard  ",
        premium: false,
        featured: true
    )

    let query = filters.query(limit: 24, offset: 48)
    let endpoint = Endpoints.activities(query)

    #expect(filters.hasActiveFilters)
    #expect(endpoint.queryValue("search") == "rocket ship")
    #expect(endpoint.queryValue("category") == "engineering")
    #expect(endpoint.queryValue("difficulty") == "hard")
    #expect(endpoint.queryValue("age_range") == "6-8")
    #expect(endpoint.queryValue("time_max") == "30")
    #expect(endpoint.queryValue("energy_level") == "active")
    #expect(endpoint.queryValue("scrap_tag") == "cardboard")
    #expect(endpoint.queryValue("premium") == "false")
    #expect(endpoint.queryValue("featured") == "true")
    #expect(endpoint.queryValue("limit") == "24")
    #expect(endpoint.queryValue("offset") == "48")
}

@Test func browseCatalogFiltersOmitEmptySearchAndCanClear() {
    var filters = BrowseCatalogFilters(searchText: "   ", category: .art, scrapTag: "\n")

    #expect(filters.normalizedSearch == nil)
    #expect(filters.normalizedScrapTag == nil)
    #expect(filters.hasActiveFilters)

    filters.clear()

    #expect(!filters.hasActiveFilters)
    #expect(filters.query().queryItems.map(\.name) == ["limit", "offset"])
}

@Test func browseCatalogPageStateResetsPaginationWhenFiltersChange() {
    var state = BrowseCatalogPageState(limit: 20, offset: 40, total: 100)
    #expect(state.canLoadMore)
    #expect(state.currentQuery().queryItems.first { $0.name == "offset" }?.value == "40")

    state.replaceFilters(BrowseCatalogFilters(searchText: "paint"))

    #expect(state.currentQuery().queryItems.first { $0.name == "offset" }?.value == "0")
    #expect(state.currentQuery().queryItems.first { $0.name == "search" }?.value == "paint")
    #expect(state.canLoadMore)
}

@Test func browseCatalogPageStateTracksLoadMoreBoundary() {
    var state = BrowseCatalogPageState(limit: 20, offset: 20, total: 45)
    let advanced = state.advancePageIfPossible()
    #expect(advanced)
    #expect(state.currentQuery().queryItems.first { $0.name == "offset" }?.value == "40")

    state.markLoaded(total: 45)
    #expect(!state.canLoadMore)
    let advancedAtEnd = state.advancePageIfPossible()
    #expect(!advancedAtEnd)
}

@Test func projectCatalogFiltersBuildBackendProjectsQuery() {
    let materialID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    let filters = ProjectCatalogFilters(
        age: 7,
        materialIDs: [materialID],
        timeLimitMinutes: 30,
        cleanupLevel: .low,
        supervisionLevel: .adultAssist,
        difficulty: .easy
    )

    let endpoint = Endpoints.projects(filters.query())

    #expect(endpoint.queryValue("age") == "7")
    #expect(endpoint.queryValue("materials") == materialID.uuidString)
    #expect(endpoint.queryValue("time") == "30")
    #expect(endpoint.queryValue("cleanup_level") == "low")
    #expect(endpoint.queryValue("supervision_level") == "adult_assist")
    #expect(endpoint.queryValue("difficulty") == "easy")
}

private extension Endpoint {
    func queryValue(_ name: String) -> String? {
        queryItems.first { $0.name == name }?.value
    }
}
