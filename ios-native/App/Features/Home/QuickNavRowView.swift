import SwiftUI

struct QuickNavRowView: View {
    @Bindable var router: AppRouter

    private struct Item {
        let title: String
        let icon: String
        let isEnabled: Bool
        let action: () -> Void
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x3) {
                ForEach(items, id: \.title) { item in
                    Button(action: item.action) {
                        VStack(spacing: SLSpacing.x2) {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(item.isEnabled ? SLColor.ink : SLColor.mutedText)
                                .frame(width: 56, height: 56)
                                .background(SLColor.surface, in: Circle())
                            Text(item.title)
                                .font(SLFont.caption)
                                .foregroundStyle(item.isEnabled ? SLColor.ink : SLColor.mutedText)
                        }
                        .frame(width: 72)
                    }
                    .buttonStyle(.plain)
                    .disabled(!item.isEnabled)
                }
            }
        }
    }

    private var items: [Item] {
        [
            Item(title: "Materials", icon: "hand.point.up.left", isEnabled: true) {
                router.selectedTab = .create
                router.createPath = [.manual]
            },
            Item(title: "Browse", icon: "safari", isEnabled: true) {
                router.selectedTab = .browse
            },
            Item(title: "Build Log", icon: "book.closed", isEnabled: true) {
                router.selectedTab = .buildLog
                router.buildLogPath = []
            },
            Item(title: "Saved", icon: "bookmark", isEnabled: true) {
                router.selectedTab = .buildLog
                router.buildLogPath = []
            },
            // Challenges is Phase 6 work; shown disabled rather than routing nowhere.
            Item(title: "Challenges", icon: "trophy", isEnabled: false) {},
        ]
    }
}
