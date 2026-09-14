import ScrapLabModels
import SwiftUI

/// Spec §4.4: the time/cleanup/supervision chip row that must render directly beneath a
/// project card's description and always be visible — never hidden behind a tap. All
/// three parameters are non-optional so a card cannot be built without it.
struct RealityIndicatorRow: View {
    enum Style {
        /// Full-text chips (Browse's list, full-width cards).
        case full
        /// Icon-only badges for narrow compact cards (Home's horizontal scroll, Create's
        /// results grid) — three full-text chips need ~270-280pt, which overflows a
        /// ~148pt compact card and gets silently clipped. Icon-only needs ~100pt.
        /// Full text is preserved for VoiceOver via `.accessibilityLabel`.
        case compact
    }

    let timeMinutes: Int
    let cleanupMinutes: Int
    let supervisionLevel: SupervisionLevel?
    var style: Style = .full

    private var cleanupLevel: CleanupLevel { .from(estimatedCleanupMinutes: cleanupMinutes) }

    var body: some View {
        switch style {
        case .full:
            HStack(spacing: SLSpacing.x2) {
                MetadataChip(label: "\(timeMinutes) min", systemImage: "clock")
                MetadataChip(label: "\(cleanupLevel.displayName) mess", systemImage: "trash")
                SupervisionBadge(level: supervisionLevel)
            }
        case .compact:
            HStack(spacing: SLSpacing.x2) {
                iconBadge(systemImage: "clock", tint: SLColor.mutedText, accessibilityLabel: "\(timeMinutes) minutes")
                iconBadge(systemImage: "trash", tint: SLColor.mutedText, accessibilityLabel: "\(cleanupLevel.displayName) mess")
                iconBadge(
                    systemImage: supervisionLevel?.symbol ?? "questionmark.circle",
                    tint: supervisionLevel?.tint ?? SLColor.mutedText,
                    accessibilityLabel: supervisionLevel?.displayTitle ?? "Supervision level unknown"
                )
            }
        }
    }

    private func iconBadge(systemImage: String, tint: Color, accessibilityLabel: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(SLColor.softFill(tint), in: Circle())
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Reality indicators") {
    VStack(alignment: .leading, spacing: SLSpacing.x4) {
        RealityIndicatorRow(timeMinutes: 20, cleanupMinutes: 8, supervisionLevel: .checkIn)
        RealityIndicatorRow(timeMinutes: 20, cleanupMinutes: 8, supervisionLevel: .checkIn, style: .compact)
    }
    .padding()
}
