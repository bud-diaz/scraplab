import SwiftUI

/// Generic swipeable, view-aligned card carousel with a page-dot indicator, adapted from
/// `AgeBandCarouselView`'s scroll mechanics (`.scrollTargetLayout()` + `.scrollTargetBehavior(.viewAligned)`
/// + `.scrollPosition(id:)`). No page-dot component existed anywhere in this codebase before this.
///
/// Unlike `AgeBandCarouselView` — which is *designed* to show multiple cards at once with
/// one scaled up as "active" under the default `.viewAligned` limit behavior (`.automatic`,
/// which packs as many items per page as fit) — this component's cards are wide enough
/// relative to the viewport that `.automatic` produced an ambiguous, non-item-aligned
/// snap point (two cards each half-cut at the screen edges instead of one fully visible).
/// `.viewAligned(limitBehavior: .always)` forces exactly one item to be the snap target
/// per page regardless of viewport/item-width ratio, which is what "swipe one card at a
/// time" actually requires.
struct SwipeableCardCarousel<Item: Identifiable, Content: View>: View {
    let items: [Item]
    // 320pt (not the initially-considered 280pt) gives `.full`-layout `ProjectCardView`'s
    // three-chip `RealityIndicatorRow` ~288pt of inner content width after the card's own
    // 16pt/side padding — matching what it had full-bleed in Browse's list, where this
    // exact row was originally sized to fit. 280pt would have reintroduced the same
    // chip-overflow bug this session already hit once, especially after the font bump.
    var cardWidth: CGFloat = 320
    @ViewBuilder let content: (Item, Bool) -> Content

    @State private var selectedID: Item.ID?

    var body: some View {
        VStack(spacing: SLSpacing.x3) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SLSpacing.x4) {
                    ForEach(items) { item in
                        content(item, item.id == selectedID)
                            .frame(width: cardWidth)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $selectedID)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedID)
            .onAppear {
                if selectedID == nil { selectedID = items.first?.id }
            }

            if items.count > 1 {
                pageDots
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: SLSpacing.x1) {
            ForEach(items) { item in
                let isActive = item.id == selectedID
                Circle()
                    .fill(isActive ? SLColor.primary : SLColor.line)
                    .frame(width: isActive ? 8 : 6, height: isActive ? 8 : 6)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedID)
    }
}
