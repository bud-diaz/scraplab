import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import ScrapLabAPI

@Test func activitiesQueryUsesBackendSnakeCaseParameterNames() {
    let endpoint = Endpoints.activities(ActivitiesQuery(
        category: "art",
        difficulty: .adaptive,
        ageRange: "6-8",
        timeMax: 30,
        energyLevel: .chaoticGoblin,
        scrapTag: "cardboard",
        search: "rocket ship",
        premium: false,
        featured: true,
        limit: 12,
        offset: 24
    ))

    #expect(endpoint.path == "/api/activities")
    #expect(endpoint.method == .get)
    #expect(endpoint.queryValue("category") == "art")
    #expect(endpoint.queryValue("difficulty") == "adaptive")
    #expect(endpoint.queryValue("age_range") == "6-8")
    #expect(endpoint.queryValue("time_max") == "30")
    #expect(endpoint.queryValue("energy_level") == "chaotic-goblin")
    #expect(endpoint.queryValue("scrap_tag") == "cardboard")
    #expect(endpoint.queryValue("search") == "rocket ship")
    #expect(endpoint.queryValue("premium") == "false")
    #expect(endpoint.queryValue("featured") == "true")
    #expect(endpoint.queryValue("limit") == "12")
    #expect(endpoint.queryValue("offset") == "24")
    #expect(endpoint.queryValue("timeMax") == nil)
    #expect(endpoint.queryValue("ageRange") == nil)
}

@Test func projectsQueryEncodesMaterialIDsAsCommaSeparatedBackendParameter() {
    let first = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let second = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let endpoint = Endpoints.projects(ProjectsQuery(
        age: 7,
        materialIDs: [first, second],
        time: 45,
        cleanupLevel: "low",
        supervisionLevel: "adult_assist",
        difficulty: "easy"
    ))

    #expect(endpoint.queryValue("age") == "7")
    #expect(endpoint.queryValue("materials") == "\(first.uuidString),\(second.uuidString)")
    #expect(endpoint.queryValue("time") == "45")
    #expect(endpoint.queryValue("cleanup_level") == "low")
    #expect(endpoint.queryValue("supervision_level") == "adult_assist")
    #expect(endpoint.queryValue("difficulty") == "easy")
    #expect(endpoint.queryValue("materialIDs") == nil)
}

@Test func materialsQueryOnlyEmitsCategoryWhenPresent() {
    #expect(Endpoints.materials(MaterialsQuery()).queryItems.isEmpty)
    #expect(Endpoints.materials(MaterialsQuery(category: "paper")).queryValue("category") == "paper")
}

@Test func clientAppendsQueryItemsToRequestURL() async throws {
    let transport: APIClient.Transport = { request in
        let components = try #require(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        #expect(components.path == "/api/activities")
        #expect(components.queryItems?.first(where: { $0.name == "search" })?.value == "rocket ship")
        #expect(components.queryItems?.first(where: { $0.name == "featured" })?.value == "true")
        return (Data("{}".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }

    let client = APIClient(baseURL: URL(string: "https://example.com")!, transport: transport)
    let _: EmptyResponse = try await client.send(Endpoints.activities(ActivitiesQuery(search: "rocket ship", featured: true)))
}

private extension Endpoint {
    func queryValue(_ name: String) -> String? {
        queryItems.first { $0.name == name }?.value
    }
}
