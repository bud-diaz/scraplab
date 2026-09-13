import ScrapLabModels
import SwiftUI

/// Ports Home's hardcoded "Suggested For You" row to `GET /api/activities?featured=true&limit=10`
/// instead of `src/lib/mock-data.ts` — see the plan's own "Home's Suggested For You row has
/// no API" risk note. Zero server changes needed; the route already supports `featured`.
struct SuggestedForYouView: View {
    let activities: [Activity]
    let onSeeAll: () -> Void
    let onSelect: (Activity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            HStack {
                Text("Suggested For You").font(SLFont.headline).foregroundStyle(SLColor.ink)
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(SLFont.caption.weight(.semibold))
                    .foregroundStyle(SLColor.primaryPressed)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SLSpacing.x3) {
                    ForEach(activities, id: \.id) { activity in
                        Button {
                            onSelect(activity)
                        } label: {
                            compactCard(for: activity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func compactCard(for activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text(ActivityCategoryTheme.emoji(for: activity.category))
                .font(.system(size: 28))
                .frame(width: 140, height: 80)
                .background(SLColor.cream100)
            Text(activity.title)
                .font(SLFont.callout.weight(.semibold))
                .foregroundStyle(SLColor.ink)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
            MetadataChip(label: "\(activity.timeMinutes) min", systemImage: "clock")
        }
        .padding(SLSpacing.x2)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .clipShape(RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}
