import ScrapLabModels
import SwiftUI

private extension SupervisionLevel {
    var displayTitle: String {
        switch self {
        case .independent: "Independent"
        case .checkIn: "Light Check-In"
        case .adultAssist: "Adult Assist"
        case .fullSupervision: "Full Supervision"
        }
    }

    var symbol: String {
        switch self {
        case .independent: "checkmark.shield"
        case .checkIn: "eye"
        case .adultAssist: "person.2"
        case .fullSupervision: "exclamationmark.shield"
        }
    }

    var tint: Color {
        switch self {
        case .independent: SLColor.leafText
        case .checkIn: SLColor.cautionText
        case .adultAssist, .fullSupervision: SLColor.coralText
        }
    }

    var fill: Color {
        switch self {
        case .independent: SLColor.leaf
        case .checkIn: SLColor.caution
        case .adultAssist, .fullSupervision: SLColor.coral
        }
    }
}

struct SupervisionBadge: View {
    let level: SupervisionLevel?

    var body: some View {
        Label(level?.displayTitle ?? "Supervision level unknown", systemImage: level?.symbol ?? "questionmark.circle")
            .font(SLFont.caption.weight(.semibold))
            .foregroundStyle(level?.tint ?? SLColor.bodyText)
            .padding(.horizontal, SLSpacing.x3)
            .padding(.vertical, SLSpacing.x2)
            .background((level?.fill ?? SLColor.kraft500).opacity(0.15), in: Capsule())
    }
}

#Preview("Supervision") {
    VStack {
        ForEach(SupervisionLevel.allCases, id: \.self) { SupervisionBadge(level: $0) }
        SupervisionBadge(level: nil)
    }
}
