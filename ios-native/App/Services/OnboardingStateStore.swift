import Foundation
import Observation
import ScrapLabModels

/// `UserDefaults`-backed adapter for the one-time onboarding flag, same protocol/store
/// boundary pattern as `SessionStore`/`EntitlementsStore`. Gates only on first launch,
/// independent of auth — guest browsing must still work while this is shown.
@MainActor @Observable
final class OnboardingStateStore {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedAgeBand = "onboardingSelectedAgeBand"
    }

    private let defaults: UserDefaults

    private(set) var hasCompletedOnboarding: Bool
    private(set) var selectedAgeBand: AgeBand?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        selectedAgeBand = defaults.string(forKey: Keys.selectedAgeBand).flatMap(AgeBand.init(rawValue:))
    }

    var shouldShowOnboarding: Bool {
        OnboardingCompletionPolicy.shouldShowOnboarding(hasSeenOnboarding: hasCompletedOnboarding)
    }

    func markCompleted(selectedAgeBand: AgeBand?) {
        hasCompletedOnboarding = true
        self.selectedAgeBand = selectedAgeBand
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        if let selectedAgeBand {
            defaults.set(selectedAgeBand.rawValue, forKey: Keys.selectedAgeBand)
        }
    }
}
