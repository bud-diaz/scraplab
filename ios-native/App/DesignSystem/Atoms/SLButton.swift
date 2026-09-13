import SwiftUI

enum SLButtonVariant {
    case primary, secondary, hero, destructive
}

enum SLButtonSize {
    case compact, regular, large

    var verticalPadding: CGFloat {
        switch self { case .compact: 8; case .regular: 12; case .large: 16 }
    }

    var font: Font {
        switch self { case .compact: SLFont.callout.weight(.semibold); case .regular, .large: SLFont.headline }
    }
}

struct SLButtonStyle: ButtonStyle {
    let variant: SLButtonVariant
    let size: SLButtonSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundStyle(foreground)
            .padding(.horizontal, SLSpacing.x5)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: size == .compact ? nil : .infinity)
            .background(background.opacity(configuration.isPressed ? 0.82 : 1), in: Capsule())
            .overlay(Capsule().strokeBorder(border, lineWidth: variant == .secondary ? 1 : 0))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 1), value: configuration.isPressed)
    }

    private var foreground: Color { variant == .secondary ? SLColor.ink : .white }
    private var background: Color {
        switch variant {
        case .primary: SLColor.primary
        case .secondary: SLColor.surface
        case .hero: SLColor.hero
        case .destructive: SLColor.coral
        }
    }
    private var border: Color { variant == .secondary ? SLColor.line : .clear }
}

extension ButtonStyle where Self == SLButtonStyle {
    static func scrapLab(_ variant: SLButtonVariant = .primary, size: SLButtonSize = .regular) -> Self {
        .init(variant: variant, size: size)
    }
}

#Preview("Buttons") {
    VStack(spacing: SLSpacing.x4) {
        Button("Start creating") {}.buttonStyle(.scrapLab())
        Button("Learn more") {}.buttonStyle(.scrapLab(.secondary))
        Button("Hero action") {}.buttonStyle(.scrapLab(.hero))
        Button("Delete") {}.buttonStyle(.scrapLab(.destructive, size: .compact))
    }
    .padding()
    .background(SLColor.pageBackground)
}
