import Foundation
import Testing
@testable import ScrapLabModels

@Test func snakeCasePayloadDecodesUUIDsDatesAndNestedModels() throws {
    let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let json = """
    {"id":"\(id.uuidString)","user_id":"22222222-2222-2222-2222-222222222222","name":null,"age":7,"created_at":"2026-09-11T12:34:56.123Z"}
    """.data(using: .utf8)!

    let child = try ModelCoding.decoder().decode(ChildProfile.self, from: json)

    #expect(child.id == id)
    #expect(child.name == nil)
    #expect(child.age == 7)
    #expect(child.createdAt.timeIntervalSince1970 > 0)
}

@Test(arguments: [
    ("independent", SupervisionLevel.independent),
    ("some-help", SupervisionLevel.adultAssist),
    ("adult-needed", SupervisionLevel.fullSupervision),
])
func activitySupervisionLabelsNormalizeConservatively(raw: String, expected: SupervisionLevel) {
    #expect(SupervisionLevel.normalizedActivityLabel(raw) == expected)
}

@Test func unknownActivitySupervisionDoesNotGuess() {
    #expect(SupervisionLevel.normalizedActivityLabel("occasionally-nearby") == nil)
}

@Test func activityExposesNormalizedSupervision() {
    let activity = Activity.fixture(supervisionLevel: "some-help")
    #expect(activity.normalizedSupervisionLevel == .adultAssist)
}

@Test func accessInfoDecodesUnlimitedLimitsAsNil() throws {
    let json = #"{"plan":"plus","limits":{"dailyRecommendations":null,"photoScan":true,"childProfiles":null,"savedProjects":null},"usage":{"recommendationsToday":2}}"#.data(using: .utf8)!

    let access = try ModelCoding.decoder().decode(AccessInfo.self, from: json)

    #expect(access.plan == .plus)
    #expect(access.limits.dailyRecommendations == nil)
    #expect(access.limits.childProfiles == nil)
    #expect(access.limits.savedProjects == nil)
}

@Test func syncRevenueCatResponseDecodesServerReconciledPlan() throws {
    let json = #"{"plan":"free"}"#.data(using: .utf8)!
    let response = try ModelCoding.decoder().decode(SyncRevenueCatResponse.self, from: json)
    #expect(response.plan == .free)
}

@Test func mutatingEndpointRequestsEncodeBackendCamelCaseBodies() throws {
    let projectId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let childId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let materialId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    try expectEncodedObject(ActivityRecommendationRequest(materialIds: [materialId], childAge: 8, requestId: "req-1")) { object in
        #expect(object["materialIds"] as? [String] == [materialId.uuidString])
        #expect(object["childAge"] as? Int == 8)
        #expect(object["requestId"] as? String == "req-1")
        #expect(object["material_ids"] == nil)
    }

    try expectEncodedObject(ChildProfileRequest(name: nil, age: 7)) { object in
        #expect(object.keys.contains("name"))
        #expect(object["name"] is NSNull)
        #expect(object["age"] as? Int == 7)
    }

    try expectEncodedObject(HouseholdInventoryRequest(materialId: materialId, source: .manual, stapleFlag: true, confidenceScore: 0.8)) { object in
        #expect(object["materialId"] as? String == materialId.uuidString)
        #expect(object["source"] as? String == "manual")
        #expect(object["stapleFlag"] as? Bool == true)
        #expect(object["confidenceScore"] as? Double == 0.8)
        #expect(object["staple_flag"] == nil)
    }

    try expectEncodedObject(StartBuildRequest(projectId: projectId, childProfileId: childId)) { object in
        #expect(object["projectId"] as? String == projectId.uuidString)
        #expect(object["childProfileId"] as? String == childId.uuidString)
    }

    try expectEncodedObject(UpdateBuildProgressRequest(completionStatus: .completed, currentStep: 4)) { object in
        #expect(object["completionStatus"] as? String == "completed")
        #expect(object["currentStep"] as? Int == 4)
    }

    try expectEncodedObject(SaveProjectRequest(projectId: projectId)) { object in
        #expect(object["projectId"] as? String == projectId.uuidString)
    }
}

private func expectEncodedObject<T: Encodable>(_ value: T, checks: ([String: Any]) throws -> Void) throws {
    let data = try ModelCoding.encoder().encode(value)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    try checks(object)
}

private extension Activity {
    static func fixture(supervisionLevel: String) -> Activity {
        Activity(
            id: UUID(), title: "Test", slug: "test", category: .art,
            oneLiner: nil, description: nil, ageRanges: [.sixToEight],
            difficulty: .easy, timeMinutes: 10, estimatedCleanupMinutes: 2,
            attentionSpanFit: "short", energyLevel: .calm, soloOrGroup: "solo",
            supervisionLevel: supervisionLevel, environment: [], materialsRequired: [],
            materialsOptional: [], scrapTags: [], themeTags: [], skillTags: [],
            promptType: "open", learningAngle: nil, expansionPrompts: [], safetyNotes: [],
            heroImagePrompt: nil, premium: false, featured: false, seasonal: nil,
            inventoryFriendly: true, remixable: true, createdAt: .distantPast, projectId: nil
        )
    }
}
