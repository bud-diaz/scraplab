import SwiftUI

/// Spec §4.6: a floating, pill-shaped bottom bar (Canvas White on lavender/everyday
/// screens) with a filled Craft Orange circle behind the active tab's icon, replacing
/// the stock `TabView` chrome that `RootTabView` hides via `.toolbar(.hidden, for: .tabBar)`.
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    private struct Item {
        let tab: AppTab
        let systemImage: String
        let label: String
    }

    private let items: [Item] = [
        Item(tab: .home, systemImage: "house.fill", label: "Home"),
        Item(tab: .create, systemImage: "plus", label: "Create"),
        Item(tab: .buildLog, systemImage: "book.closed.fill", label: "Build Log"),
        Item(tab: .browse, systemImage: "safari.fill", label: "Browse"),
        Item(tab: .profile, systemImage: "person.fill", label: "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                let isActive = selection == item.tab
                Button {
                    selection = item.tab
                } label: {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isActive ? Color.white : SLColor.mutedText)
                        .frame(width: 44, height: 44)
                        .background {
                            if isActive {
                                Circle().fill(SLColor.primary)
                            }
                        }
                }
                .accessibilityLabel(item.label)
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, SLSpacing.x2)
        .background(SLColor.surface, in: Capsule())
        .slShadow(.floating)
        .padding(.horizontal, SLSpacing.x6)
        .padding(.bottom, SLSpacing.x2)
    }
}

#Preview("Floating tab bar") {
    @Previewable @State var selection: AppTab = .home
    ZStack(alignment: .bottom) {
        SLColor.pageBackground.ignoresSafeArea()
        FloatingTabBar(selection: $selection)
    }
}
