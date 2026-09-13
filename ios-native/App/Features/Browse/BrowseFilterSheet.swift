import ScrapLabAPI
import ScrapLabModels
import SwiftUI

struct BrowseFilterSheet: View {
    @Binding var filters: BrowseCatalogFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    chipRow(ActivityCategory.allCases, selection: $filters.category) {
                        $0.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
                    }
                }
                Section("Difficulty") {
                    chipRow(ActivityQueryDifficulty.allCases, selection: $filters.difficulty) { $0.rawValue.capitalized }
                }
                Section("Age") {
                    chipRow(ActivityAgeRange.allCases, selection: $filters.ageRange) {
                        $0 == .family ? "Family" : $0.rawValue
                    }
                }
                Section("Time") {
                    chipRow(BrowseTimeFilter.allCases, selection: $filters.timeLimit) { "\($0.rawValue) min" }
                }
                Section("Energy") {
                    chipRow(ActivityQueryEnergyLevel.allCases, selection: $filters.energyLevel) {
                        $0.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Clear") { filters.clear() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func chipRow<T: Hashable>(_ options: [T], selection: Binding<T?>, label: @escaping (T) -> String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SLSpacing.x2) {
                ForEach(options, id: \.self) { option in
                    FilterChip(title: label(option), isSelected: selection.wrappedValue == option) {
                        selection.wrappedValue = selection.wrappedValue == option ? nil : option
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical, SLSpacing.x2)
        .padding(.horizontal, SLSpacing.x4)
    }
}

#Preview("Browse Filters") {
    BrowseFilterSheet(filters: .constant(BrowseCatalogFilters(category: .engineering)))
}
