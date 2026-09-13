import Foundation
import Testing
@testable import ScrapLabAPI

@Test func endpointNamespaceIncludesAppRoutesWithDeclaredMethods() {
    #expect(Endpoints.activities.method == .get)
    #expect(Endpoints.projects.method == .get)
    #expect(Endpoints.recommendations.method == .post)
    #expect(Endpoints.activityRecommendations.method == .post)
    #expect(Endpoints.inventory.method == .get)
    #expect(Endpoints.createInventoryItem.method == .post)
    #expect(Endpoints.access.method == .get)
    #expect(Endpoints.buildHistory.method == .get)
    #expect(Endpoints.createBuildHistory.method == .post)
    #expect(Endpoints.savedProjects.method == .get)
    #expect(Endpoints.saveProject.method == .post)
    #expect(Endpoints.scanMaterials.method == .post)
    #expect(Endpoints.deleteAccount.method == .delete)
    #expect(Endpoints.syncRevenueCat.method == .post)
    #expect(Endpoints.mysteryMaterials.method == .get)
    #expect(Endpoints.materials.method == .get)
    #expect(Endpoints.childProfiles.method == .get)
    #expect(Endpoints.createChildProfile.method == .post)
}

@Test func dynamicEndpointsSafelyAppendUUIDPathComponents() {
    let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    #expect(Endpoints.activity(id).path == "/api/activities/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")
    #expect(Endpoints.project(id).method == .get)
    #expect(Endpoints.updateInventoryItem(id).method == .patch)
    #expect(Endpoints.deleteInventoryItem(id).method == .delete)
    #expect(Endpoints.updateBuildHistory(id).method == .patch)
    #expect(Endpoints.deleteSavedProject(id).method == .delete)
    #expect(Endpoints.updateChildProfile(id).method == .patch)
    #expect(Endpoints.deleteChildProfile(id).method == .delete)
}

@Test func activityAndProjectEndpointsAcceptSlugsForDeepLinkLookup() {
    #expect(Endpoints.activity("rocket-ship").path == "/api/activities/rocket-ship")
    #expect(Endpoints.project("rocket-ship").path == "/api/projects/rocket-ship")

    let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    #expect(Endpoints.activity(id).path == Endpoints.activity(id.uuidString).path)
    #expect(Endpoints.project(id).path == Endpoints.project(id.uuidString).path)
}
