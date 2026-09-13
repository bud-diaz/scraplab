import ScrapLabModels
import SwiftUI

/// Ports `AiSuggestionCard` from `src/app/create/results/page.tsx`.
struct AiSuggestionCardView: View {
    let suggestion: AiSuggestion
    let index: Int
    @State private var isExpanded = false

    private static let emojis = ["💡", "🎨", "🔨", "✂️", "🌟"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Text(Self.emojis[index % Self.emojis.count])
                    .font(.system(size: 36))
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .background(SLColor.cream100)
                MetadataChip(label: "AI Idea", systemImage: "sparkles")
                    .padding(SLSpacing.x2)
            }
            VStack(alignment: .leading, spacing: SLSpacing.x2) {
                Text(suggestion.title).font(SLFont.headline).foregroundStyle(SLColor.ink).lineLimit(2)
                Text(suggestion.description).font(SLFont.caption).foregroundStyle(SLColor.bodyText).lineLimit(2)
                HStack(spacing: SLSpacing.x2) {
                    MetadataChip(label: "\(suggestion.timeMinutes) min", systemImage: "clock")
                    MetadataChip(label: "\(suggestion.cleanupLevel) mess", systemImage: "trash")
                }
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Label(isExpanded ? "Hide steps" : "Show steps", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                        .font(SLFont.caption.weight(.semibold))
                        .foregroundStyle(SLColor.primaryPressed)
                }
                .buttonStyle(.plain)
                if isExpanded {
                    VStack(alignment: .leading, spacing: SLSpacing.x1) {
                        ForEach(Array(suggestion.steps.enumerated()), id: \.offset) { i, step in
                            Text("\(i + 1). \(step)").font(SLFont.caption).foregroundStyle(SLColor.ink)
                        }
                    }
                }
            }
            .padding(SLSpacing.x3)
        }
        .background(SLColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }
}
