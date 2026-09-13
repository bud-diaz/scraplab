import Foundation
import Testing
@testable import ScrapLabModels

private func makeMaterial(id: UUID = UUID(), name: String, category: String) -> Material {
    Material(id: id, name: name, aliases: [], category: category, icon: nil, createdAt: Date(timeIntervalSince1970: 0))
}

private func makeActivity(timeMinutes: Int = 15, difficulty: ActivityDifficulty = .easy, ageRanges: [ActivityAgeRange] = [.sixToEight]) -> Activity {
    Activity(
        id: UUID(), title: "Test Activity", slug: "test-activity", category: .art, oneLiner: nil, description: nil,
        ageRanges: ageRanges, difficulty: difficulty, timeMinutes: timeMinutes, estimatedCleanupMinutes: 5,
        attentionSpanFit: "medium", energyLevel: .calm, soloOrGroup: "solo", supervisionLevel: "independent",
        environment: [], materialsRequired: [], materialsOptional: [], scrapTags: [], themeTags: [], skillTags: [],
        promptType: "build", learningAngle: nil, expansionPrompts: [], safetyNotes: [], heroImagePrompt: nil,
        premium: false, featured: false, seasonal: nil, inventoryFriendly: true, remixable: true, createdAt: Date(), projectId: nil
    )
}

@Test func createAgeClampsToBackendBoundsWithoutTouchingThePickerRange() {
    #expect(CreateAge.clampToBackendRange(1) == 3)
    #expect(CreateAge.clampToBackendRange(30) == 18)
    #expect(CreateAge.clampToBackendRange(9) == 9)
    #expect(CreateAge.pickerRange == 3...12)
}

@Test func materialCatalogFilterMatchesByCategoryAndCaseInsensitiveSearch() {
    let cardboard = makeMaterial(name: "Cardboard Box", category: "recyclables")
    let glitter = makeMaterial(name: "Glitter", category: "craft-supplies")
    let filter = MaterialCatalogFilter(searchText: "board", category: nil)

    #expect(filter.apply(to: [cardboard, glitter]) == [cardboard])
    #expect(MaterialCatalogFilter().apply(to: [cardboard, glitter]).count == 2)
    #expect(MaterialCatalogFilter(category: "craft-supplies").apply(to: [cardboard, glitter]) == [glitter])
}

@Test func materialCatalogFilterDerivesCategoriesInFirstSeenOrder() {
    let materials = [
        makeMaterial(name: "A", category: "recyclables"),
        makeMaterial(name: "B", category: "craft-supplies"),
        makeMaterial(name: "C", category: "recyclables"),
    ]
    #expect(MaterialCatalogFilter.categories(in: materials) == ["recyclables", "craft-supplies"])
}

@Test func materialSelectionStateTogglesAndEnforcesBackendMaxSelectable() {
    var state = MaterialSelectionState()
    let ids = (0..<MaterialSelectionState.maxSelectable + 5).map { _ in UUID() }

    #expect(!state.canSubmit)
    for id in ids { state.toggle(id) }

    #expect(state.selectedMaterialIDs.count == MaterialSelectionState.maxSelectable)
    #expect(state.canSubmit)

    let first = ids[0]
    state.toggle(first)
    #expect(!state.isSelected(first))
    #expect(state.selectedMaterialIDs.count == MaterialSelectionState.maxSelectable - 1)
}

@Test func materialSelectionStateRemoveDropsFromTray() {
    let id = UUID()
    var state = MaterialSelectionState(selectedMaterialIDs: [id])
    state.remove(id)
    #expect(!state.isSelected(id))
    #expect(!state.canSubmit)
}

@Test func materialSelectionStateBuildsClampedRequestWithDeterministicDedupeKey() {
    let idA = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    let idB = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    let state = MaterialSelectionState(selectedMaterialIDs: [idB, idA])

    let request = state.recommendationRequest(childAge: 25)

    #expect(request.materialIds == [idB, idA])
    #expect(request.childAge == 18)
    #expect(request.requestId == "\(idA.uuidString),\(idB.uuidString):age18")
}

@Test func createResultsFilterMirrorsWebFilterChipSemantics() {
    let quickEasyFamily = makeActivity(timeMinutes: 15, difficulty: .easy, ageRanges: [.family])
    let slowHard = makeActivity(timeMinutes: 45, difficulty: .hard, ageRanges: [.nineToTwelve])
    let quickMatch = ActivityMatch(activity: quickEasyFamily, matchedCount: 1, totalRequired: 1, matchScore: 1, matchLabel: "Perfect Match")
    let slowMatch = ActivityMatch(activity: slowHard, matchedCount: 1, totalRequired: 2, matchScore: 0.5, matchLabel: "Good Match")

    #expect(CreateResultsFilter.all.matches(quickMatch))
    #expect(CreateResultsFilter.all.matches(slowMatch))
    #expect(CreateResultsFilter.quick.matches(quickMatch))
    #expect(!CreateResultsFilter.quick.matches(slowMatch))
    #expect(CreateResultsFilter.easy.matches(quickMatch))
    #expect(!CreateResultsFilter.easy.matches(slowMatch))
    #expect(CreateResultsFilter.family.matches(quickMatch))
    #expect(!CreateResultsFilter.family.matches(slowMatch))
}
