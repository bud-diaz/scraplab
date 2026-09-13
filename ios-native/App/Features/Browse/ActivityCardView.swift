import ScrapLabModels
import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    var matchLabel: String?

    var body: some View {
        HStack(alignment: .top, spacing: SLSpacing.x4) {
            Text(ActivityCategoryTheme.emoji(for: activity.category))
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(SLColor.cream100, in: RoundedRectangle(cornerRadius: SLRadius.card))

            VStack(alignment: .leading, spacing: SLSpacing.x2) {
                HStack {
                    Text(activity.title).font(SLFont.headline).foregroundStyle(SLColor.ink)
                    if activity.premium {
                        Image(systemName: "sparkles").font(.caption).foregroundStyle(SLColor.hero)
                    }
                    Spacer()
                }
                if let oneLiner = activity.oneLiner {
                    Text(oneLiner).font(SLFont.callout).foregroundStyle(SLColor.bodyText).lineLimit(2)
                }
                HStack(spacing: SLSpacing.x2) {
                    MetadataChip(label: "\(activity.timeMinutes) min", systemImage: "clock")
                    MetadataChip(label: activity.difficulty.rawValue.capitalized)
                    if let matchLabel {
                        MetadataChip(label: matchLabel, systemImage: "checkmark.seal")
                    }
                    SupervisionBadge(level: activity.normalizedSupervisionLevel)
                }
            }
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}

#Preview("Activity Card") {
    ActivityCardView(activity: .preview)
        .padding()
        .background(SLColor.pageBackground)
}

extension Activity {
    static var preview: Activity {
        Activity(
            id: UUID(), title: "Cardboard Rocket Ship", slug: "cardboard-rocket-ship", category: .engineering,
            oneLiner: "Build a rocket from a shipping box and blast off into pretend space.", description: nil,
            ageRanges: [.sixToEight], difficulty: .medium, timeMinutes: 30, estimatedCleanupMinutes: 10,
            attentionSpanFit: "medium", energyLevel: .active, soloOrGroup: "solo", supervisionLevel: "independent",
            environment: ["indoor"], materialsRequired: ["cardboard box"], materialsOptional: ["paint"],
            scrapTags: ["cardboard"], themeTags: ["space"], skillTags: ["engineering"], promptType: "build",
            learningAngle: nil, expansionPrompts: [], safetyNotes: [], heroImagePrompt: nil, premium: false,
            featured: true, seasonal: nil, inventoryFriendly: true, remixable: true, createdAt: Date(), projectId: nil
        )
    }
}
