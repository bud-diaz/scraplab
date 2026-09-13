import ScrapLabModels
import SwiftUI

struct MaterialTileView: View {
    let material: ScrapLabModels.Material
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
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
            .background(isSelected ? SLColor.primary.opacity(0.12) : SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: SLRadius.card).stroke(isSelected ? SLColor.primary : SLColor.line, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}
