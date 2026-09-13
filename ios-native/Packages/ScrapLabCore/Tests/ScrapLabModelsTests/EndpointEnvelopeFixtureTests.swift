import Foundation
import Testing
@testable import ScrapLabModels

@Test(arguments: [
    ("activities", ActivitiesResponse.self),
    ("activity-detail", ActivityResponse.self),
    ("projects", ProjectsResponse.self),
    ("project-detail", ProjectResponse.self),
    ("activity-recommendations", ActivityRecommendationsResponse.self),
    ("recommendations", RecommendationsResponse.self),
    ("household-inventory", HouseholdInventoryResponse.self),
    ("access", AccessInfo.self),
    ("build-history", BuildHistoryResponse.self),
    ("saved-projects", SavedProjectsResponse.self),
    ("child-profiles", ChildProfilesResponse.self),
    ("materials", MaterialsResponse.self),
    ("mystery-materials", MysteryMaterialsResponse.self),
    ("scan-materials", ScanResult.self),
] as [(String, any Decodable.Type)])
func apiEnvelopeFixtureDecodes(_ fixtureName: String, _ type: any Decodable.Type) throws {
    let data = try fixtureData(named: fixtureName)
    _ = try ModelCoding.decoder().decode(type, from: data)
}

@Test func endpointFixturesExerciseKnownSharpEdges() throws {
    let projectDetail = try decodeFixture("project-detail", as: ProjectResponse.self)
    #expect(projectDetail.project.projectMaterials.first?.material.name == "Cardboard tube")
    #expect(projectDetail.substitutions.first?.sourceMaterialId.uuidString.lowercased() == "33333333-3333-3333-3333-333333333333")

    let mystery = try decodeFixture("mystery-materials", as: MysteryMaterialsResponse.self)
    #expect(mystery.materials.first?.name == "Cardboard tube")

    let activityRecommendations = try decodeFixture("activity-recommendations", as: ActivityRecommendationsResponse.self)
    #expect(activityRecommendations.matches.first?.activity.normalizedSupervisionLevel == .adultAssist)
    #expect(activityRecommendations.aiSuggestions.first?.timeMinutes == 15)

    let materials = try decodeFixture("materials", as: MaterialsResponse.self)
    #expect(materials.grouped?["paper"]?.first?.aliases == ["tube", "roll"])
}

private func decodeFixture<T: Decodable>(_ fixtureName: String, as type: T.Type) throws -> T {
    try ModelCoding.decoder().decode(type, from: fixtureData(named: fixtureName))
}

private func fixtureData(named fixtureName: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: fixtureName, withExtension: "json"))
    return try Data(contentsOf: url)
}
