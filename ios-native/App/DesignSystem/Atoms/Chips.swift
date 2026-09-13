import SwiftUI

struct MetadataChip: View {
    let label: String
    var systemImage: String?

    var body: some View {
        Group {
            if let systemImage {
                Label(label, systemImage: systemImage)
            } else {
                Text(label)
            }
        }
        .font(SLFont.caption.weight(.medium))
        .foregroundStyle(SLColor.bodyText)
        .padding(.horizontal, SLSpacing.x3)
        .padding(.vertical, SLSpacing.x2)
        .background(SLColor.surface, in: Capsule())
        .overlay(Capsule().stroke(SLColor.line))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(SLFont.callout.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : SLColor.bodyText)
            .padding(.horizontal, SLSpacing.x4)
            .padding(.vertical, SLSpacing.x2)
            .background(isSelected ? SLColor.primary : SLColor.surface, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : SLColor.line))
    }
}

#Preview("Chips") {
    HStack {
        MetadataChip(label: "20 min", systemImage: "clock")
        FilterChip(title: "Cardboard", isSelected: true) {}
        FilterChip(title: "Paper", isSelected: false) {}
    }.padding()
}
