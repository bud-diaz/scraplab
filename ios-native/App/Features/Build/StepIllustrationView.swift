import ScrapLabModels
import SwiftUI

/// Hand-ported geometric approximations of `src/components/ui/StepIllustration.tsx`'s ten
/// SVGs (circles/rects/paths in an 80×80 box, per the plan). Two things the web version
/// lacks that this adds: `accessibilityHidden` (the instruction text already carries the
/// meaning) and a static pose under Reduce Motion instead of the web's always-on CSS
/// animation. Exact geometry is a visual judgment call with no source SVG to trace, so
/// treat the shapes as a first pass pending a look on an actual screen.
struct StepIllustrationView: View {
    let action: StepIllustrationAction
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SLRadius.card)
                .fill(SLColor.cream100)
            Canvas { context, size in
                let scale = size.width / 80
                context.scaleBy(x: scale, y: scale)
                draw(in: &context)
            }
            .frame(width: 56, height: 56)
        }
        .frame(width: 56, height: 56)
        .accessibilityHidden(true)
        .onAppear { if !reduceMotion { animate = true } }
        .scaleEffect(animate ? 1.04 : 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: animate)
    }

    private func draw(in context: inout GraphicsContext) {
        let stroke = SLColor.walnut600
        let fill = SLColor.primary
        switch action {
        case .cut: drawScissors(&context, stroke: stroke, fill: fill)
        case .roll: drawRoll(&context, stroke: stroke, fill: fill)
        case .fold: drawFold(&context, stroke: stroke, fill: fill)
        case .tape: drawTape(&context, stroke: stroke, fill: fill)
        case .glue: drawGlue(&context, stroke: stroke, fill: fill)
        case .decorate: drawDecorate(&context, fill: fill)
        case .thread: drawThread(&context, stroke: stroke, fill: fill)
        case .tie: drawTie(&context, stroke: stroke)
        case .launch: drawLaunch(&context, fill: fill)
        case .fallback: drawSparkle(&context, fill: fill)
        }
    }

    private func drawScissors(_ context: inout GraphicsContext, stroke: Color, fill: Color) {
        let pivot = CGPoint(x: 40, y: 40)
        for angle: Double in [-28, 28] {
            let radians = angle * .pi / 180
            let end = CGPoint(x: pivot.x + 34 * cos(radians), y: pivot.y - 34 * sin(radians) - 10)
            var blade = Path()
            blade.move(to: pivot)
            blade.addLine(to: end)
            context.stroke(blade, with: .color(stroke), lineWidth: 3)
            context.fill(Circle().path(in: CGRect(x: end.x - 8, y: end.y - 8, width: 16, height: 16)), with: .color(.clear))
            context.stroke(Circle().path(in: CGRect(x: end.x - 8, y: end.y - 8, width: 16, height: 16)), with: .color(stroke), lineWidth: 3)
        }
        context.fill(Circle().path(in: CGRect(x: pivot.x - 4, y: pivot.y - 4, width: 8, height: 8)), with: .color(fill))
    }

    private func drawRoll(_ context: inout GraphicsContext, stroke: Color, fill: Color) {
        context.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: 24, y: 22, width: 32, height: 36)), with: .color(fill.opacity(0.25)))
        context.stroke(Ellipse().path(in: CGRect(x: 24, y: 16, width: 32, height: 12)), with: .color(stroke), lineWidth: 3)
        context.stroke(Ellipse().path(in: CGRect(x: 24, y: 52, width: 32, height: 12)), with: .color(stroke), lineWidth: 3)
        var arrow = Path()
        arrow.addArc(center: CGPoint(x: 40, y: 40), radius: 26, startAngle: .degrees(-40), endAngle: .degrees(160), clockwise: false)
        context.stroke(arrow, with: .color(fill), lineWidth: 2)
    }

    private func drawFold(_ context: inout GraphicsContext, stroke: Color, fill: Color) {
        context.fill(RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: 18, y: 20, width: 44, height: 40)), with: .color(fill.opacity(0.2)))
        var flap = Path()
        flap.move(to: CGPoint(x: 62, y: 20))
        flap.addLine(to: CGPoint(x: 62, y: 44))
        flap.addLine(to: CGPoint(x: 38, y: 20))
        flap.closeSubpath()
        context.fill(flap, with: .color(fill.opacity(0.45)))
        var crease = Path()
        crease.move(to: CGPoint(x: 38, y: 20))
        crease.addLine(to: CGPoint(x: 62, y: 44))
        context.stroke(crease, with: .color(stroke), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
    }

    private func drawTape(_ context: inout GraphicsContext, stroke: Color, fill: Color) {
        context.stroke(Circle().path(in: CGRect(x: 20, y: 20, width: 40, height: 40)), with: .color(stroke), lineWidth: 4)
        context.fill(Circle().path(in: CGRect(x: 34, y: 34, width: 12, height: 12)), with: .color(fill.opacity(0.3)))
        var strip = Path()
        strip.move(to: CGPoint(x: 52, y: 26))
        strip.addLine(to: CGPoint(x: 66, y: 18))
        strip.addLine(to: CGPoint(x: 62, y: 30))
        strip.addLine(to: CGPoint(x: 50, y: 34))
        strip.closeSubpath()
        context.fill(strip, with: .color(fill.opacity(0.6)))
    }

    private func drawGlue(_ context: inout GraphicsContext, stroke: Color, fill: Color) {
        context.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: 26, y: 30, width: 28, height: 32)), with: .color(fill.opacity(0.3)))
        context.fill(RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: 34, y: 18, width: 12, height: 14)), with: .color(stroke.opacity(0.6)))
        context.fill(Rectangle().path(in: CGRect(x: 32, y: 40, width: 16, height: 8)), with: .color(.white.opacity(0.7)))
        context.fill(Ellipse().path(in: CGRect(x: 38, y: 58, width: 6, height: 8)), with: .color(fill))
    }

    private func drawDecorate(_ context: inout GraphicsContext, fill: Color) {
        let colors: [Color] = [fill, SLColor.leaf, SLColor.hero]
        for (index, tilt) in [-18.0, 0.0, 18.0].enumerated() {
            var marker = context
            marker.translateBy(x: 26 + Double(index) * 14, y: 44)
            marker.rotate(by: .degrees(tilt))
            marker.fill(RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: -5, y: -22, width: 10, height: 26)), with: .color(colors[index]))
            marker.fill(Circle().path(in: CGRect(x: -4, y: 2, width: 8, height: 8)), with: .color(colors[index]))
        }
    }

    private func drawThread(_ context: inout GraphicsContext, stroke: Color, fill: Color) {
        context.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: 16, y: 34, width: 48, height: 14)), with: .color(fill.opacity(0.25)))
        context.fill(RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: 20, y: 24, width: 3, height: 34)), with: .color(stroke))
        context.stroke(Circle().path(in: CGRect(x: 18, y: 22, width: 6, height: 6)), with: .color(stroke), lineWidth: 1.5)
        var thread = Path()
        thread.move(to: CGPoint(x: 22, y: 24))
        thread.addCurve(to: CGPoint(x: 50, y: 50), control1: CGPoint(x: 40, y: 10), control2: CGPoint(x: 30, y: 60))
        context.stroke(thread, with: .color(fill), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
    }

    private func drawTie(_ context: inout GraphicsContext, stroke: Color) {
        for offset: Double in [-8, 8] {
            var loop = Path()
            loop.addEllipse(in: CGRect(x: 40 + offset - 12, y: 34, width: 24, height: 16))
            context.stroke(loop, with: .color(stroke), lineWidth: 3)
        }
        context.fill(Circle().path(in: CGRect(x: 36, y: 38, width: 8, height: 8)), with: .color(stroke))
    }

    private func drawLaunch(_ context: inout GraphicsContext, fill: Color) {
        var body = Path()
        body.addRoundedRect(in: CGRect(x: 32, y: 14, width: 16, height: 36), cornerSize: CGSize(width: 8, height: 8))
        context.fill(body, with: .color(fill))
        context.fill(Circle().path(in: CGRect(x: 36, y: 24, width: 8, height: 8)), with: .color(.white.opacity(0.8)))
        var leftFin = Path()
        leftFin.move(to: CGPoint(x: 32, y: 40))
        leftFin.addLine(to: CGPoint(x: 20, y: 54))
        leftFin.addLine(to: CGPoint(x: 32, y: 50))
        leftFin.closeSubpath()
        context.fill(leftFin, with: .color(fill.opacity(0.8)))
        var rightFin = Path()
        rightFin.move(to: CGPoint(x: 48, y: 40))
        rightFin.addLine(to: CGPoint(x: 60, y: 54))
        rightFin.addLine(to: CGPoint(x: 48, y: 50))
        rightFin.closeSubpath()
        context.fill(rightFin, with: .color(fill.opacity(0.8)))
        var flame = Path()
        flame.move(to: CGPoint(x: 36, y: 50))
        flame.addLine(to: CGPoint(x: 40, y: 66))
        flame.addLine(to: CGPoint(x: 44, y: 50))
        flame.closeSubpath()
        context.fill(flame, with: .color(SLColor.caution))
    }

    private func drawSparkle(_ context: inout GraphicsContext, fill: Color) {
        var star = Path()
        let center = CGPoint(x: 40, y: 40)
        for i in 0..<10 {
            let radius: Double = i.isMultiple(of: 2) ? 22 : 9
            let angle = Double(i) * .pi / 5 - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
        }
        star.closeSubpath()
        context.fill(star, with: .color(fill))
        context.fill(Circle().path(in: CGRect(x: 58, y: 16, width: 6, height: 6)), with: .color(SLColor.caution))
        context.fill(Circle().path(in: CGRect(x: 14, y: 54, width: 5, height: 5)), with: .color(SLColor.caution))
    }
}

#Preview("Step Illustrations") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: SLSpacing.x3) {
            ForEach(StepIllustrationAction.allCases, id: \.self) { action in
                StepIllustrationView(action: action)
            }
        }
        .padding()
    }
}
