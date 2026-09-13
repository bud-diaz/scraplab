import ScrapLabModels
import SwiftUI

/// Renders nothing when there is nothing in progress, matching the web's `return null`.
struct ContinueBuildingView: View {
    let entries: [BuildHistory]
    let onSelect: (Project) -> Void

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: SLSpacing.x3) {
                Text("Continue Building").font(SLFont.headline).foregroundStyle(SLColor.ink)
                ForEach(entries, id: \.id) { entry in
                    if let project = entry.project {
                        Button {
                            onSelect(project)
                        } label: {
                            row(for: project)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func row(for project: Project) -> some View {
        HStack(spacing: SLSpacing.x3) {
            Text(ProjectDisplayTheme.theme(for: project.slug).emoji)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(SLColor.cream100, in: RoundedRectangle(cornerRadius: SLRadius.card))
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title).font(SLFont.body).foregroundStyle(SLColor.ink)
                Text("In progress").font(SLFont.caption).foregroundStyle(SLColor.bodyText)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(SLColor.mutedText)
        }
        .padding(SLSpacing.x3)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.card))
    }
}
