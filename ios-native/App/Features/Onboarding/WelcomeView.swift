import SwiftUI

/// Spec §4.1: full-bleed ScrapLab Blue hero, centered mascot, a speech-bubble value-prop
/// panel, and a bold "Let's Start!" pill button bottom-center advancing to the age-band carousel.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            SLColor.hero.ignoresSafeArea()

            VStack(spacing: SLSpacing.x8) {
                Spacer()

                FlatVectorMascotView(pose: .wave)
                    .frame(width: 160, height: 160)

                VStack(spacing: SLSpacing.x4) {
                    Text("Welcome to ScrapLab")
                        .font(SLFont.largeTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    speechBubble
                }

                Spacer()

                Button(action: onContinue) {
                    Label("Let's Start!", systemImage: "arrow.right")
                        .font(SLFont.headline.weight(.heavy))
                        .foregroundStyle(SLColor.hero)
                        .padding(.horizontal, SLSpacing.x8)
                        .padding(.vertical, SLSpacing.x4)
                        .background(Color.white, in: Capsule())
                }
                .accessibilityLabel("Let's Start")
                .padding(.bottom, SLSpacing.x10)
            }
            .padding(.horizontal, SLSpacing.x6)
        }
    }

    private var speechBubble: some View {
        Text("Turn your junk drawer into your kid's next big build!")
            .font(SLFont.body)
            .foregroundStyle(SLColor.ink)
            .multilineTextAlignment(.center)
            .padding(SLSpacing.x5)
            .background(Color.white, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
    }
}

#Preview("Welcome") {
    WelcomeView(onContinue: {})
}
