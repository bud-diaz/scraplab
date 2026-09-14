import Foundation

/// Spec §4.1's age-band mascot cards for the onboarding child-profile carousel. This is
/// presentational/local-only state — it pre-seeds UI defaults (e.g. the manual material
/// picker's age stepper) and is distinct from the real, backend-persisted child profile
/// created via `OnboardingChildProfileBuilder` after sign-up.
public enum AgeBand: String, CaseIterable, Equatable, Sendable, Codable {
    case littleBuilder
    case juniorMaker
    case masterCrafter

    public var title: String {
        switch self {
        case .littleBuilder: "Little Builder"
        case .juniorMaker: "Junior Maker"
        case .masterCrafter: "Master Crafter"
        }
    }

    public var ageRangeLabel: String {
        switch self {
        case .littleBuilder: "3–5"
        case .juniorMaker: "6–8"
        case .masterCrafter: "9–10"
        }
    }

    public var ageRange: ClosedRange<Int> {
        switch self {
        case .littleBuilder: 3...5
        case .juniorMaker: 6...8
        case .masterCrafter: 9...10
        }
    }

    /// A single representative age for pickers that need one `Int` rather than a range.
    public var defaultAge: Int { ageRange.lowerBound }
}

public enum OnboardingCompletionPolicy {
    public static func shouldShowOnboarding(hasSeenOnboarding: Bool) -> Bool {
        !hasSeenOnboarding
    }
}
