import Foundation
import ScrapLabModels
import SwiftUI

/// Renders nothing when there are no staple-flagged materials, matching the web's `return null`.
struct HouseholdStaplesView: View {
    let staples: [HouseholdInventory]
    let onEdit: () -> Void
    let onFindBuilds: ([UUID]) -> Void

    var body: some View {
        if !staples.isEmpty {
            VStack(alignment: .leading, spacing: SLSpacing.x3) {
                HStack {
                    Text("Household Staples").font(SLFont.headline).foregroundStyle(SLColor.ink)
                    Spacer()
                    Button("Edit", action: onEdit)
                        .font(SLFont.caption.weight(.semibold))
                        .foregroundStyle(SLColor.primaryPressed)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SLSpacing.x2) {
                        ForEach(staples, id: \.id) { item in
                            MetadataChip(label: "\(item.material?.icon ?? "📦") \(item.material?.name ?? "Material")")
                        }
                    }
                }
                Button("Find builds with these →") {
                    onFindBuilds(staples.map(\.materialId))
                }
                .buttonStyle(.scrapLab(.secondary, size: .compact))
            }
        }
    }
}
