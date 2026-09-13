import ScrapLabModels
import SwiftUI

/// Presentational only — the unsave button is layered on top as a sibling at the call
/// site rather than nested inside this card, since a `Button` inside a `NavigationLink`
/// label fights the link for the tap gesture instead of getting its own hit target.
struct SavedProjectCardView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text(ProjectDisplayTheme.theme(for: project.slug).emoji)
                .font(.system(size: 32))
                .frame(maxWidth: .infinity)
                .frame(height: 88)
                .background(SLColor.cream100)
            VStack(alignment: .leading, spacing: SLSpacing.x1) {
                Text(project.title).font(SLFont.headline).foregroundStyle(SLColor.ink).lineLimit(2)
                HStack(spacing: SLSpacing.x2) {
                    MetadataChip(label: "\(project.timeMinutes) min", systemImage: "clock")
                    MetadataChip(label: project.difficulty.rawValue.capitalized)
                }
            }
            .padding(.horizontal, SLSpacing.x3)
            .padding(.bottom, SLSpacing.x3)
        }
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .clipShape(RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}
