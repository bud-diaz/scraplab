import ScrapLabModels
import SwiftUI

/// Not tappable, matching the web's History tab (no `onClick`/`Link` on these rows there).
struct BuildHistoryRowView: View {
    let entry: BuildHistory

    var body: some View {
        HStack(spacing: SLSpacing.x3) {
            Text(entry.project.map { ProjectDisplayTheme.theme(for: $0.slug).emoji } ?? "🔧")
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(SLColor.cream100, in: RoundedRectangle(cornerRadius: SLRadius.card))

            VStack(alignment: .leading, spacing: SLSpacing.x1) {
                Text(entry.project?.title ?? "Untitled project").font(SLFont.headline).foregroundStyle(SLColor.ink)
                if let project = entry.project {
                    Text("\(project.timeMinutes) min · \(project.cleanupLevel.rawValue) mess")
                        .font(SLFont.caption)
                        .foregroundStyle(SLColor.bodyText)
                }
            }

            Spacer()

            Text(BuildHistoryStatusBadge.title(for: entry.completionStatus))
                .font(SLFont.caption.weight(.semibold))
                .padding(.horizontal, SLSpacing.x3)
                .padding(.vertical, SLSpacing.x1)
                .background(badgeColor, in: Capsule())
                .foregroundStyle(SLColor.ink)
        }
        .padding(SLSpacing.x3)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.card))
    }

    private var badgeColor: Color {
        switch entry.completionStatus {
        case .completed: SLColor.sunshine
        case .abandoned: SLColor.kraft400
        case .started: SLColor.cream100
        }
    }
}
