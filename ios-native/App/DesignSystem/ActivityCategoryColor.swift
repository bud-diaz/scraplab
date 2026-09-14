import ScrapLabModels
import SwiftUI

/// App-target companion to `ActivityCategoryTheme` (which only maps category → emoji,
/// since `ScrapLabModels` is Linux-testable and cannot import SwiftUI). Gives every
/// activity/project card a distinct, vibrant category color instead of a flat lavender
/// tile, for the whole-app "kiddie" redesign pass.
enum ActivityCategoryColor {
    static func fill(for category: ActivityCategory) -> Color {
        switch category {
        case .engineering: SLColor.hero
        case .science: SLColor.turquoise
        case .art: SLColor.bubblegum
        case .storytelling: SLColor.grape
        case .pretendPlay: SLColor.sunshine
        case .cooperative: SLColor.leaf
        case .puzzle: SLColor.primary
        case .seasonal: SLColor.coral
        }
    }
}
