import ScrapLabModels
import SwiftUI

struct MaterialsChecklistView: View {
    let checklist: MaterialsChecklistState
    let onToggle: (MaterialsChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x4) {
            if !checklist.requiredItems.isEmpty {
                section(title: "You'll need", items: checklist.requiredItems)
            }
            if !checklist.optionalItems.isEmpty {
                section(title: "Nice to have", items: checklist.optionalItems)
            }
        }
    }

    private func section(title: String, items: [MaterialsChecklistItem]) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Text(title).font(SLFont.headline).foregroundStyle(SLColor.ink)
            ForEach(items) { item in
                Button {
                    onToggle(item)
                } label: {
                    HStack(spacing: SLSpacing.x3) {
                        Image(systemName: checklist.isChecked(item) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(checklist.isChecked(item) ? SLColor.leafText : SLColor.mutedText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(SLFont.body).foregroundStyle(SLColor.ink)
                            if let note = item.quantityNote {
                                Text(note).font(SLFont.caption).foregroundStyle(SLColor.mutedText)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
