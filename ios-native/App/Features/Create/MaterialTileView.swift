import ScrapLabModels
import SwiftUI

struct MaterialTileView: View {
    let material: ScrapLabModels.Material
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: SLSpacing.x1) {
                    Text(material.icon ?? "📦").font(.system(size: 28))
                    Text(material.name)
                        .font(SLFont.caption)
                        .foregroundStyle(SLColor.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(SLSpacing.x2)
                .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.card))
                .overlay(RoundedRectangle(cornerRadius: SLRadius.card).stroke(isSelected ? SLColor.primary : SLColor.line, lineWidth: isSelected ? 2 : 1))

                if isSelected {
                    checkBadge
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var checkBadge: some View {
        ZStack {
            Circle().fill(SLColor.primary)
            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: 18, height: 18)
        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
        .offset(x: 6, y: -6)
    }
}
