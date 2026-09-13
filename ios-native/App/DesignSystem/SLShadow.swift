import SwiftUI

enum SLShadowElevation {
    case card
    case raised
    case floating
}

private struct SLShadowModifier: ViewModifier {
    let elevation: SLShadowElevation

    func body(content: Content) -> some View {
        switch elevation {
        case .card:
            content
                .shadow(color: SLColor.ink.opacity(0.09), radius: 4, y: 2)
                .shadow(color: SLColor.ink.opacity(0.05), radius: 1, y: 1)
        case .raised:
            content
                .shadow(color: SLColor.ink.opacity(0.14), radius: 8, y: 4)
                .shadow(color: SLColor.ink.opacity(0.07), radius: 2, y: 2)
        case .floating:
            content
                .shadow(color: SLColor.ink.opacity(0.12), radius: 12, y: 8)
                .shadow(color: SLColor.ink.opacity(0.07), radius: 3, y: 2)
        }
    }
}

extension View {
    func slShadow(_ elevation: SLShadowElevation = .card) -> some View {
        modifier(SLShadowModifier(elevation: elevation))
    }
}
