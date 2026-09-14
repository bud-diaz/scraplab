import ScrapLabModels
import SwiftUI

/// Spec §4.1's "hand-pick your character" pattern, adapted to friendly age-band cards
/// (not literal game avatars): a horizontally-scrollable, view-aligned carousel with the
/// active card enlarged on an orange rounded-square background.
struct AgeBandCarouselView: View {
    let onGetStarted: (AgeBand?) -> Void
    @State private var selectedID: AgeBand? = .littleBuilder

    var body: some View {
        HeroSheetContainer(heroHeight: 220) {
            heroHeader
        } sheetContent: {
            VStack(spacing: SLSpacing.x8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SLSpacing.x4) {
                        ForEach(AgeBand.allCases, id: \.self) { band in
                            ageBandCard(band).id(band)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, SLSpacing.x10)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedID)
                .frame(height: 220)

                Button("Let's Go!") { onGetStarted(selectedID) }
                    .buttonStyle(.scrapLab(.hero))
                    .padding(.horizontal, SLSpacing.x6)

                Spacer()
            }
            .padding(.top, SLSpacing.x6)
        }
    }

    private var heroHeader: some View {
        VStack(spacing: SLSpacing.x3) {
            Text("Hand-pick your builder")
                .font(SLFont.title)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("We'll tailor ideas to their age.")
                .font(SLFont.body)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, SLSpacing.x6)
        .padding(.top, SLSpacing.x10)
    }

    private func ageBandCard(_ band: AgeBand) -> some View {
        let isActive = band == selectedID
        return VStack(spacing: SLSpacing.x3) {
            FlatVectorMascotView(pose: .wave)
                .frame(width: isActive ? 72 : 52, height: isActive ? 72 : 52)
            Text(band.title)
                .font(SLFont.headline)
                .foregroundStyle(SLColor.ink)
                .multilineTextAlignment(.center)
            Text(band.ageRangeLabel)
                .font(SLFont.caption)
                .foregroundStyle(SLColor.bodyText)
        }
        .padding(SLSpacing.x4)
        .frame(width: 160)
        .background(isActive ? SLColor.orange100 : SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .overlay(RoundedRectangle(cornerRadius: SLRadius.largeCard).stroke(isActive ? SLColor.primary : .clear, lineWidth: 2))
        .scaleEffect(isActive ? 1 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedID)
    }
}

#Preview("Age band carousel") {
    AgeBandCarouselView(onGetStarted: { _ in })
}
