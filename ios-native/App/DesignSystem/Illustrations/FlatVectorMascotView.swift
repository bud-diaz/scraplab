import SwiftUI

/// The pose a `FlatVectorMascotView` should strike. Shared across onboarding, empty
/// states, and the build-complete celebration so the app has one consistent character
/// rather than a bespoke drawing per screen.
enum MascotPose {
    case wave
    case celebrate
    case thinking
    case empty
}

/// A friendly "scrap mascot" — a cardboard-robot character built from craft materials —
/// drawn as flat, hand-composed SwiftUI shapes (not a photographic or 3D-rendered asset).
/// Sized to fill its given frame; callers should constrain size via `.frame(...)`.
struct FlatVectorMascotView: View {
    let pose: MascotPose

    private var leftArmAngle: Angle {
        switch pose {
        case .wave: .degrees(-35)
        case .celebrate: .degrees(-140)
        case .thinking: .degrees(-10)
        case .empty: .degrees(12)
        }
    }

    private var rightArmAngle: Angle {
        switch pose {
        case .wave: .degrees(150)
        case .celebrate: .degrees(140)
        case .thinking: .degrees(70)
        case .empty: .degrees(-12)
        }
    }

    private var headTilt: Angle {
        switch pose {
        case .wave: .degrees(-4)
        case .celebrate: .degrees(0)
        case .thinking: .degrees(6)
        case .empty: .degrees(8)
        }
    }

    private var antennaTilt: Angle {
        pose == .empty ? .degrees(28) : .degrees(0)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                if pose == .celebrate { sparkles(size: size) }

                VStack(spacing: size * 0.02) {
                    head(size: size).rotationEffect(headTilt)

                    ZStack {
                        torso(size: size)
                        arm(size: size, tint: SLColor.orange400)
                            .rotationEffect(leftArmAngle, anchor: .topLeading)
                            .offset(x: -size * 0.18)
                        arm(size: size, tint: SLColor.orange500)
                            .rotationEffect(rightArmAngle, anchor: .topTrailing)
                            .offset(x: size * 0.18)
                    }

                    HStack(spacing: size * 0.1) {
                        Capsule().fill(SLColor.walnut700).frame(width: size * 0.1, height: size * 0.16)
                        Capsule().fill(SLColor.walnut700).frame(width: size * 0.1, height: size * 0.16)
                    }
                }
                .frame(width: size, height: size, alignment: .center)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
    }

    private func head(size: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(SLColor.ink)
                .frame(width: size * 0.03, height: size * 0.12)
                .offset(y: -size * 0.28)
                .rotationEffect(antennaTilt, anchor: .bottom)
            Circle()
                .fill(SLColor.sunshine)
                .frame(width: size * 0.09)
                .offset(y: -size * 0.34)
                .rotationEffect(antennaTilt, anchor: .bottomLeading)

            RoundedRectangle(cornerRadius: size * 0.14)
                .fill(SLColor.orange300)
                .frame(width: size * 0.42, height: size * 0.34)

            HStack(spacing: size * 0.08) {
                Circle().fill(SLColor.ink).frame(width: size * 0.05)
                Circle().fill(SLColor.ink).frame(width: size * 0.05)
            }
            .offset(y: -size * 0.02)

            Capsule()
                .fill(SLColor.ink)
                .frame(width: pose == .thinking ? size * 0.05 : size * 0.12, height: size * 0.025)
                .offset(y: size * 0.08)
        }
    }

    private func torso(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.1)
            .fill(SLColor.orange500)
            .frame(width: size * 0.5, height: size * 0.4)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.05)
                    .stroke(SLColor.orange700.opacity(0.4), lineWidth: max(1, size * 0.01))
                    .padding(size * 0.06)
            )
    }

    private func arm(size: CGFloat, tint: Color) -> some View {
        Capsule()
            .fill(tint)
            .frame(width: size * 0.11, height: size * 0.3)
    }

    private func sparkles(size: CGFloat) -> some View {
        ZStack {
            ForEach(Array(sparkleOffsets(size: size).enumerated()), id: \.offset) { _, point in
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.09, weight: .semibold))
                    .foregroundStyle(SLColor.sunshine)
                    .offset(x: point.x, y: point.y)
            }
        }
    }

    private func sparkleOffsets(size: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: -size * 0.4, y: -size * 0.35),
            CGPoint(x: size * 0.38, y: -size * 0.28),
            CGPoint(x: -size * 0.3, y: size * 0.32),
            CGPoint(x: size * 0.32, y: size * 0.3),
        ]
    }
}

#Preview("Mascot poses") {
    HStack(spacing: SLSpacing.x4) {
        ForEach([MascotPose.wave, .celebrate, .thinking, .empty], id: \.self) { pose in
            FlatVectorMascotView(pose: pose).frame(width: 100, height: 100)
        }
    }
    .padding()
}

extension MascotPose: CaseIterable, Hashable {}
