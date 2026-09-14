import ScrapLabModels
import SwiftUI

/// Coordinates the two first-launch onboarding steps (spec §4.1). Purely a UI overlay —
/// does not gate or interact with auth, so guest browsing is unaffected once it's dismissed.
struct OnboardingFlowView: View {
    let onFinished: (AgeBand?) -> Void
    @State private var step: Step = .welcome

    private enum Step { case welcome, ageBands }

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView(onContinue: { step = .ageBands })
        case .ageBands:
            AgeBandCarouselView(onGetStarted: onFinished)
        }
    }
}
