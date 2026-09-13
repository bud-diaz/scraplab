import Foundation
import Testing
@testable import ScrapLabModels

private func makeBuildHistory(
    completionStatus: CompletionStatus,
    completedAt: Date? = nil,
    startedAt: Date = Date(timeIntervalSince1970: 0)
) -> BuildHistory {
    BuildHistory(
        id: UUID(), userId: UUID(), projectId: UUID(), childProfileId: nil,
        completionStatus: completionStatus, currentStep: 0, startedAt: startedAt, completedAt: completedAt
    )
}

private func makeInventory(stapleFlag: Bool) -> HouseholdInventory {
    HouseholdInventory(id: UUID(), userId: UUID(), materialId: UUID(), confidenceScore: nil, source: .manual, stapleFlag: stapleFlag, updatedAt: Date())
}

@Test func buildStepPlayerStateClampsResumedStepIntoBounds() {
    #expect(BuildStepPlayerState(totalSteps: 5, currentStep: 99).currentStep == 4)
    #expect(BuildStepPlayerState(totalSteps: 5, currentStep: -3).currentStep == 0)
    #expect(BuildStepPlayerState(totalSteps: 0, currentStep: 2).currentStep == 0)
}

@Test func buildStepPlayerStateAdvancesAndRetreatsWithinBounds() {
    var state = BuildStepPlayerState(totalSteps: 3)
    #expect(state.isFirstStep)
    #expect(!state.isLastStep)

    state.retreat()
    #expect(state.currentStep == 0)

    state.advance()
    state.advance()
    #expect(state.currentStep == 2)
    #expect(state.isLastStep)

    state.advance()
    #expect(state.currentStep == 2)
}

@Test func buildStepPlayerStateComputesRoundedPercent() {
    #expect(BuildStepPlayerState(totalSteps: 4, currentStep: 1).progressPercent == 25)
    #expect(BuildStepPlayerState(totalSteps: 3, currentStep: 1).progressPercent == 33)
    #expect(BuildStepPlayerState(totalSteps: 0).progressPercent == 0)
}

@Test func weeklyProgressCountsOnlyCompletedWithinTrailingSevenDays() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let recentCompleted = makeBuildHistory(completionStatus: .completed, completedAt: now.addingTimeInterval(-2 * 24 * 60 * 60))
    let staleCompleted = makeBuildHistory(completionStatus: .completed, completedAt: now.addingTimeInterval(-10 * 24 * 60 * 60))
    let inProgress = makeBuildHistory(completionStatus: .started)
    let abandoned = makeBuildHistory(completionStatus: .abandoned, completedAt: now.addingTimeInterval(-1 * 24 * 60 * 60))

    let summary = WeeklyProgressSummary(buildHistory: [recentCompleted, staleCompleted, inProgress, abandoned], now: now)

    #expect(summary.completedThisWeek == 1)
    #expect(summary.remainingToGoal == 4)
}

@Test func weeklyProgressFooterMessageMatchesWebBranchesInOrder() {
    let now = Date()
    #expect(WeeklyProgressSummary(buildHistory: [], now: now).footerMessage(isSignedIn: false) == "Sign in to track your weekly building progress.")
    #expect(WeeklyProgressSummary(buildHistory: [], now: now).footerMessage(isSignedIn: true) == "Nothing built yet this week — let's fix that.")

    let fiveCompleted = (0..<5).map { _ in makeBuildHistory(completionStatus: .completed, completedAt: now) }
    #expect(WeeklyProgressSummary(buildHistory: fiveCompleted, now: now).footerMessage(isSignedIn: true) == "Weekly goal reached.")

    let twoCompleted = (0..<2).map { _ in makeBuildHistory(completionStatus: .completed, completedAt: now) }
    #expect(WeeklyProgressSummary(buildHistory: twoCompleted, now: now).footerMessage(isSignedIn: true) == "3 to go this week.")
}

@Test func continueBuildingSelectorKeepsOnlyStartedCappedAtLimit() {
    let started = (0..<5).map { _ in makeBuildHistory(completionStatus: .started) }
    let completed = makeBuildHistory(completionStatus: .completed, completedAt: Date())
    let result = ContinueBuildingSelector.recentInProgress(started + [completed])

    #expect(result.count == 3)
    #expect(result.allSatisfy { $0.completionStatus == .started })
}

@Test func householdStaplesSelectorKeepsOnlyStaplesCappedAtLimit() {
    let staples = (0..<10).map { _ in makeInventory(stapleFlag: true) }
    let nonStaple = makeInventory(stapleFlag: false)
    let result = HouseholdStaplesSelector.staples(staples + [nonStaple])

    #expect(result.count == 8)
    #expect(result.allSatisfy { $0.stapleFlag })
}

@Test func buildHistoryStatusBadgeMapsEveryCompletionStatus() {
    #expect(BuildHistoryStatusBadge.title(for: .completed) == "Done")
    #expect(BuildHistoryStatusBadge.title(for: .abandoned) == "Stopped")
    #expect(BuildHistoryStatusBadge.title(for: .started) == "In Progress")
}
