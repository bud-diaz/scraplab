import Foundation
import Testing
@testable import ScrapLabModels

private func makeProject(materials: [ProjectMaterialWithMaterial]) -> ProjectWithMaterials {
    let base = Project(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "Rocket ship", slug: "rocket-ship", description: "Build a rocket.",
        ageMin: 5, ageMax: 9, timeMinutes: 30,
        cleanupLevel: .low, supervisionLevel: .independent, difficulty: .easy,
        safetyNotes: [], instructions: [], imageUrl: nil, premiumOnly: false, createdAt: Date(timeIntervalSince1970: 0)
    )
    return ProjectWithMaterials(project: base, projectMaterials: materials)
}

private func makeMaterial(id: UUID, name: String, icon: String? = nil) -> Material {
    Material(id: id, name: name, aliases: [], category: "recyclables", icon: icon, createdAt: Date(timeIntervalSince1970: 0))
}

@Test func materialsChecklistBuildsFlattenedItemsFromProjectMaterials() {
    let cardboardID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let glitterID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    let project = makeProject(materials: [
        ProjectMaterialWithMaterial(id: UUID(), projectId: UUID(), materialId: cardboardID, required: true, quantityNote: "one box", material: makeMaterial(id: cardboardID, name: "Cardboard box")),
        ProjectMaterialWithMaterial(id: UUID(), projectId: UUID(), materialId: glitterID, required: false, quantityNote: nil, material: makeMaterial(id: glitterID, name: "Glitter")),
    ])

    let state = MaterialsChecklistState.from(project)

    #expect(state.requiredItems.map(\.name) == ["Cardboard box"])
    #expect(state.optionalItems.map(\.name) == ["Glitter"])
    #expect(!state.hasEverythingRequired)
}

@Test func materialsChecklistTracksRequiredCompletionIgnoringOptional() {
    let requiredID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    let optionalID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    let project = makeProject(materials: [
        ProjectMaterialWithMaterial(id: UUID(), projectId: UUID(), materialId: requiredID, required: true, quantityNote: nil, material: makeMaterial(id: requiredID, name: "Tape")),
        ProjectMaterialWithMaterial(id: UUID(), projectId: UUID(), materialId: optionalID, required: false, quantityNote: nil, material: makeMaterial(id: optionalID, name: "Stickers")),
    ])
    var state = MaterialsChecklistState.from(project)
    let requiredItem = state.requiredItems[0]

    #expect(!state.isChecked(requiredItem))
    state.toggle(requiredItem)
    #expect(state.isChecked(requiredItem))
    #expect(state.hasEverythingRequired)

    state.toggle(requiredItem)
    #expect(!state.hasEverythingRequired)
}

@Test func materialsChecklistPreChecksMaterialsAlreadyOnHand() {
    let onHandID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    let missingID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    let project = makeProject(materials: [
        ProjectMaterialWithMaterial(id: UUID(), projectId: UUID(), materialId: onHandID, required: true, quantityNote: nil, material: makeMaterial(id: onHandID, name: "Paper towel roll")),
        ProjectMaterialWithMaterial(id: UUID(), projectId: UUID(), materialId: missingID, required: true, quantityNote: nil, material: makeMaterial(id: missingID, name: "Googly eyes")),
    ])
    var state = MaterialsChecklistState.from(project)

    state.markOnHand(materialIDs: [onHandID])

    #expect(state.checkedMaterialIDs == [onHandID])
    #expect(!state.hasEverythingRequired)
}

@Test func entitlementGateLocksOnlyPremiumContentOnFreePlan() {
    #expect(EntitlementGate.isPremiumContentLocked(premium: true, plan: .free))
    #expect(!EntitlementGate.isPremiumContentLocked(premium: false, plan: .free))
    #expect(!EntitlementGate.isPremiumContentLocked(premium: true, plan: .plus))
}

@Test func routeSegmentMirrorsBackendActivityAndProjectLookupValidation() {
    #expect(RouteSegment.isSafeActivityLookup("rocket-ship_2"))
    #expect(RouteSegment.isSafeActivityLookup("11111111-1111-1111-1111-111111111111"))
    #expect(!RouteSegment.isSafeActivityLookup("rocket ship"))
    #expect(!RouteSegment.isSafeActivityLookup(""))
    #expect(!RouteSegment.isSafeActivityLookup("id.eq.1,slug.eq.2"))

    #expect(RouteSegment.isValidProjectLookup("11111111-1111-1111-1111-111111111111"))
    #expect(RouteSegment.isValidProjectLookup("rocket-ship"))
    #expect(!RouteSegment.isValidProjectLookup("Rocket-Ship"))
    #expect(!RouteSegment.isValidProjectLookup("rocket--ship"))
    #expect(!RouteSegment.isValidProjectLookup("-rocket"))
    #expect(!RouteSegment.isValidProjectLookup(""))
}
