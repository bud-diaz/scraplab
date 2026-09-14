import SwiftUI

/// Shared "hero moment" layout: full-bleed `SLColor.hero` content on top, curved
/// via `HeroHeaderCurve`, sitting over an everyday-chrome content sheet below.
/// Reserved for onboarding/welcome and milestone-completion screens only — everyday
/// utility screens must stay flat-top per spec (no blue chrome bleeding into daily use).
struct HeroSheetContainer<HeroContent: View, SheetContent: View>: View {
    var heroHeight: CGFloat = 280
    var curveDepth: CGFloat = 36
    @ViewBuilder var heroContent: () -> HeroContent
    @ViewBuilder var sheetContent: () -> SheetContent

    var body: some View {
        ZStack(alignment: .top) {
            SLColor.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: heroHeight - curveDepth)
                sheetContent()
            }

            ZStack {
                SLColor.hero
                heroContent()
            }
            .frame(height: heroHeight)
            .clipShape(HeroHeaderCurve(depth: curveDepth))
            .ignoresSafeArea(edges: .top)
        }
    }
}
