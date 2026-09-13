import ScrapLabModels
import SwiftUI

struct WeeklyProgressView: View {
    let summary: WeeklyProgressSummary
    let isSignedIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            HStack {
                Text("This week").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
                Spacer()
                Text("Goal \(WeeklyProgressSummary.goal)").font(SLFont.caption).foregroundStyle(SLColor.mutedText)
            }
            Text("\(summary.completedThisWeek) build\(summary.completedThisWeek == 1 ? "" : "s") completed")
                .font(SLFont.title2)
                .foregroundStyle(SLColor.ink)
            ProgressView(value: summary.progressFraction)
                .tint(SLColor.primary)
            Text(summary.footerMessage(isSignedIn: isSignedIn))
                .font(SLFont.caption)
                .foregroundStyle(SLColor.bodyText)
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}
