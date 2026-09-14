import SwiftUI

/// The concave curve that separates a full-bleed hero/onboarding header from the
/// everyday-chrome content sheet below it (spec: "signature shape... gives the
/// premium app, not craft blog, feel"). `depth` controls how far the curve dips
/// into the hero area at its center relative to its side edges.
struct HeroHeaderCurve: Shape {
    var depth: CGFloat = 36

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.maxY - depth
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: baseline))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: baseline),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
