import SwiftUI

/// Ports `ChallengesList`: a hardcoded static list on the web too, not backed by any
/// `challenges` table or route. Only "Mystery Build" and "Minimal Materials Mode" link
/// anywhere real; the other two are marketing placeholders there as well.
struct ChallengesView: View {
    @Bindable var router: AppRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x3) {
                lockedRow(title: "Weekend Build Challenge", badge: "Coming Soon")

                Button {
                    router.selectedTab = .create
                    router.createPath = [.manual]
                } label: {
                    unlockedRow(title: "Minimal Materials Mode", badge: "Try It")
                }
                .buttonStyle(.plain)

                NavigationLink(value: ProfileRoute.mysteryBuild) {
                    unlockedRow(title: "Mystery Build", badge: "Plus")
                }
                .buttonStyle(.plain)

                lockedRow(title: "Kid Chooses Chaos", badge: "Coming Soon")

                UpgradeCard(title: "ScrapLab Plus", message: "Unlock Mystery Build and more with ScrapLab Plus.") {
                    router.presentedSheet = .upgrade
                }
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .background(SLColor.pageBackground)
    }

    private func lockedRow(title: String, badge: String) -> some View {
        HStack {
            Text(title).font(SLFont.headline).foregroundStyle(SLColor.ink)
            Spacer()
            MetadataChip(label: badge)
            Image(systemName: "lock.fill").foregroundStyle(SLColor.mutedText)
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }

    private func unlockedRow(title: String, badge: String) -> some View {
        HStack {
            Text(title).font(SLFont.headline).foregroundStyle(SLColor.ink)
            Spacer()
            MetadataChip(label: badge, systemImage: "sparkles")
            Image(systemName: "chevron.right").foregroundStyle(SLColor.mutedText)
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}
