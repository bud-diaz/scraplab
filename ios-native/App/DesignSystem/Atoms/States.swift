import SwiftUI

struct SLEmptyState: View {
    let title: String
    let message: String
    var systemImage = "shippingbox"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage).font(SLFont.title2)
        } description: {
            Text(message).font(SLFont.body).foregroundStyle(SLColor.bodyText)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.scrapLab())
            }
        }
    }
}

struct UpgradeCard: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            Image(systemName: "sparkles").font(.title2).foregroundStyle(SLColor.hero)
            Text(title).font(SLFont.title2).foregroundStyle(SLColor.ink)
            Text(message).font(SLFont.body).foregroundStyle(SLColor.bodyText)
            Button("Explore Plus", action: action).buttonStyle(.scrapLab(.hero))
        }
        .padding(SLSpacing.x5)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}

#Preview("States") {
    VStack(spacing: SLSpacing.x6) {
        SLEmptyState(title: "Nothing here yet", message: "Saved items will appear here.")
        UpgradeCard(title: "Make more with Plus", message: "Unlock additional ScrapLab features.") {}
    }
    .padding().background(SLColor.pageBackground)
}
