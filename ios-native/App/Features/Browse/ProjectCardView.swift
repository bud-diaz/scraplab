import ScrapLabModels
import SwiftUI

/// The card layout an activity/project card should use. `.compact` serves Home's
/// horizontal-scroll rows and Create's results grid; `.full` serves Browse's list.
/// One anatomy, two densities — spec §4.4 requires the Reality Indicators row to be
/// present in both.
enum CardLayout {
    case full
    case compact
}

/// Spec §4.4 card anatomy: illustration on top, title + age row, one-line description
/// (full layout only), an always-visible Reality Indicators row, and a CTA affordance.
/// The whole card is wrapped in a `NavigationLink` at each call site (Browse/Home/Create
/// results), so the CTA below is presentational, not a nested interactive control.
struct ProjectCardView: View {
    let activity: Activity
    var matchLabel: String?
    var layout: CardLayout = .full

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            illustration
            VStack(alignment: .leading, spacing: SLSpacing.x2) {
                titleRow
                if layout == .full, let oneLiner = activity.oneLiner {
                    Text(oneLiner)
                        .font(SLFont.callout)
                        .foregroundStyle(SLColor.bodyText)
                        .lineLimit(2)
                }
                RealityIndicatorRow(
                    timeMinutes: activity.timeMinutes,
                    cleanupMinutes: activity.estimatedCleanupMinutes,
                    supervisionLevel: activity.normalizedSupervisionLevel,
                    style: layout == .full ? .full : .compact
                )
                if layout == .full {
                    HStack {
                        Spacer()
                        startCTA
                    }
                }
            }
            .padding(SLSpacing.x4)
        }
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .clipShape(RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }

    private var illustration: some View {
        ZStack(alignment: .topTrailing) {
            Text(ActivityCategoryTheme.emoji(for: activity.category))
                .font(.system(size: layout == .full ? 40 : 28))
                .frame(maxWidth: .infinity)
                .frame(height: layout == .full ? 120 : 80)
                .background(ActivityCategoryColor.fill(for: activity.category).opacity(0.22))

            if let matchLabel {
                MetadataChip(label: matchLabel, systemImage: "checkmark.seal")
                    .padding(SLSpacing.x2)
            } else if activity.premium {
                Image(systemName: "sparkles")
                    .foregroundStyle(SLColor.hero)
                    .padding(SLSpacing.x2)
                    .background(Color.white, in: Circle())
                    .padding(SLSpacing.x2)
            }
        }
    }

    private var titleRow: some View {
        HStack(alignment: .top, spacing: SLSpacing.x2) {
            Text(activity.title)
                .font(SLFont.headline)
                .foregroundStyle(SLColor.ink)
                .lineLimit(2)
            Spacer()
            if let ageRange = activity.ageRanges.first {
                Text("Ages \(ageRange.rawValue)")
                    .font(SLFont.caption)
                    .foregroundStyle(SLColor.mutedText)
            }
        }
    }

    private var startCTA: some View {
        Label("Go!", systemImage: "arrow.right")
            .font(SLFont.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, SLSpacing.x4)
            .padding(.vertical, SLSpacing.x2)
            .background(SLColor.primary, in: Capsule())
    }
}

#Preview("Project card") {
    ScrollView {
        VStack(spacing: SLSpacing.x4) {
            ProjectCardView(activity: .preview, layout: .full)
            ProjectCardView(activity: .preview, layout: .compact).frame(width: 160)
        }
        .padding()
    }
    .background(SLColor.pageBackground)
}

extension Activity {
    static var preview: Activity {
        Activity(
            id: "SL-PREVIEW", title: "Cardboard Rocket Ship", slug: "cardboard-rocket-ship", category: .engineering,
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
