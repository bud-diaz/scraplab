import Foundation

/// Pure step-position state for the build player, ported from `src/app/build/[id]/page.tsx`.
/// The web clamps a resumed `current_step` into `[0, steps.length-1]` before rendering,
/// and every Back/Next tap is a local index change before the fire-and-forget PATCH.
public struct BuildStepPlayerState: Equatable, Sendable {
    public let totalSteps: Int
    public private(set) var currentStep: Int

    public init(totalSteps: Int, currentStep: Int = 0) {
        self.totalSteps = max(totalSteps, 0)
        self.currentStep = BuildStepPlayerState.clamp(currentStep, totalSteps: self.totalSteps)
    }

    public var isLastStep: Bool { totalSteps == 0 || currentStep == totalSteps - 1 }
    public var isFirstStep: Bool { currentStep == 0 }

    /// Mirrors the web's `Math.round(current/total*100)` percent-done readout.
    public var progressPercent: Int {
        guard totalSteps > 0 else { return 0 }
        return Int((Double(currentStep) / Double(totalSteps) * 100).rounded())
    }

    public mutating func advance() {
        guard !isLastStep else { return }
        currentStep += 1
    }

    public mutating func retreat() {
        guard !isFirstStep else { return }
        currentStep -= 1
    }

    private static func clamp(_ step: Int, totalSteps: Int) -> Int {
        guard totalSteps > 0 else { return 0 }
        return min(max(step, 0), totalSteps - 1)
    }
}

/// Ports the Home screen's `WeeklyProgress` card (`src/components/home/WeeklyProgress.tsx`
/// equivalent): a fixed weekly goal of 5 completed builds, counted over the trailing 7 days.
public struct WeeklyProgressSummary: Equatable, Sendable {
    public static let goal = 5

    public let completedThisWeek: Int

    public init(buildHistory: [BuildHistory], now: Date = Date()) {
        let windowStart = now.addingTimeInterval(-7 * 24 * 60 * 60)
        completedThisWeek = buildHistory.filter { entry in
            guard entry.completionStatus == .completed, let completedAt = entry.completedAt else { return false }
            return completedAt >= windowStart && completedAt <= now
        }.count
    }

    public var progressFraction: Double {
        min(1, Double(completedThisWeek) / Double(Self.goal))
    }

    public var remainingToGoal: Int {
        max(0, Self.goal - completedThisWeek)
    }

    /// Mirrors the web's four footer-message branches, in order: signed out, zero builds,
    /// goal reached, and the "N to go" default.
    public func footerMessage(isSignedIn: Bool) -> String {
        if !isSignedIn { return "Sign in to track your weekly building progress." }
        if completedThisWeek == 0 { return "Nothing built yet this week — let's fix that." }
        if completedThisWeek >= Self.goal { return "Weekly goal reached." }
        return "\(remainingToGoal) to go this week."
    }
}

/// Ports Home's `ContinueBuilding` row: in-progress builds only, most recent first, capped at 3.
public enum ContinueBuildingSelector {
    public static func recentInProgress(_ history: [BuildHistory], limit: Int = 3) -> [BuildHistory] {
        Array(history.filter { $0.completionStatus == .started }.prefix(limit))
    }
}

/// Ports Home's `HouseholdStaples` row: staple-flagged inventory only, capped at 8.
public enum HouseholdStaplesSelector {
    public static func staples(_ inventory: [HouseholdInventory], limit: Int = 8) -> [HouseholdInventory] {
        Array(inventory.filter(\.stapleFlag).prefix(limit))
    }
}

/// Ports the Library History tab's status badge text.
public enum BuildHistoryStatusBadge {
    public static func title(for status: CompletionStatus) -> String {
        switch status {
        case .completed: "Done"
        case .abandoned: "Stopped"
        case .started: "In Progress"
        }
    }
}
