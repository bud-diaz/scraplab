import ScrapLabModels
import SwiftUI

/// Spec §4.4: the time/cleanup/supervision chip row that must render directly beneath a
/// project card's description and always be visible — never hidden behind a tap. All
/// three parameters are non-optional so a card cannot be built without it.
struct RealityIndicatorRow: View {
    let timeMinutes: Int
    let cleanupMinutes: Int
    let supervisionLevel: SupervisionLevel?

    var body: some View {
        HStack(spacing: SLSpacing.x2) {
            MetadataChip(label: "\(timeMinutes) min", systemImage: "clock")
            MetadataChip(label: "\(CleanupLevel.from(estimatedCleanupMinutes: cleanupMinutes).displayName) mess", systemImage: "trash")
            SupervisionBadge(level: supervisionLevel)
        }
    }
}

#Preview("Reality indicators") {
    RealityIndicatorRow(timeMinutes: 20, cleanupMinutes: 8, supervisionLevel: .checkIn)
        .padding()
}
