import SwiftUI

private struct CreateMethodOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let badge: String?
    let isPremium: Bool
    let route: CreateRoute
}

/// Mirrors `src/components/cards/CreateMethods.tsx`. Two of the four web entries route to
/// the same manual picker there too ("Household Staples" and "Quick Build" are marketing
/// framing over the identical flow, not distinct screens) — ported as-is rather than
/// inventing native-only behavior the web doesn't have.
private let createMethodOptions: [CreateMethodOption] = [
    CreateMethodOption(icon: "hand.point.up.left.fill", title: "Choose Materials Manually", description: "Tap to select what you have on hand", badge: "Most Popular", isPremium: false, route: .manual),
    CreateMethodOption(icon: "camera.fill", title: "Scan a Photo", description: "Take a photo and we'll detect your materials", badge: nil, isPremium: true, route: .scan),
    CreateMethodOption(icon: "shippingbox.fill", title: "Use Household Staples", description: "Build from your saved usual materials", badge: "Coming Soon", isPremium: false, route: .manual),
    CreateMethodOption(icon: "bolt.fill", title: "Quick Build", description: "3 materials or fewer — fast project ideas", badge: nil, isPremium: false, route: .manual),
]

struct CreateMethodListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: SLSpacing.x3) {
                ForEach(createMethodOptions) { option in
                    NavigationLink(value: option.route) {
                        row(for: option)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("Start with what you have")
        .background(SLColor.pageBackground)
    }

    private func row(for option: CreateMethodOption) -> some View {
        HStack(spacing: SLSpacing.x4) {
            Image(systemName: option.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(SLColor.primary, in: RoundedRectangle(cornerRadius: SLRadius.card))
            VStack(alignment: .leading, spacing: SLSpacing.x1) {
                HStack(spacing: SLSpacing.x2) {
                    Text(option.title).font(SLFont.headline).foregroundStyle(SLColor.ink)
                    if option.isPremium {
                        MetadataChip(label: "Plus", systemImage: "sparkles")
                    } else if let badge = option.badge {
                        MetadataChip(label: badge)
                    }
                }
                Text(option.description).font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(SLColor.mutedText)
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}

#Preview("Create Methods") {
    NavigationStack { CreateMethodListView() }
}
