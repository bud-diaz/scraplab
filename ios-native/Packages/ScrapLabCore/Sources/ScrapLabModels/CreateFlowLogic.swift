import Foundation

public enum CreateAge {
    public static let minSupported = 3
    public static let maxSupported = 18
    /// Mirrors the web manual-picker's age dropdown (`AGE_OPTIONS` in
    /// `src/app/create/manual/page.tsx`); the backend itself accepts ages up to 18.
    public static let pickerRange = 3...12
    /// The scan flow's confirm action does not expose an age control on the web either —
    /// it hardcodes 7. Ported as-is rather than inventing a picker the web doesn't have.
    public static let scanDefault = 7

    public static func clampToBackendRange(_ age: Int) -> Int {
        min(max(age, minSupported), maxSupported)
    }
}

/// Client-side search/category filtering over `GET /api/materials`, which only supports
/// a server-side `category` filter (see `src/app/api/materials/route.ts`) — search is a
/// UI-only concern on both the web and native clients.
public struct MaterialCatalogFilter: Equatable, Sendable {
    public var searchText: String
    public var category: String?

    public init(searchText: String = "", category: String? = nil) {
        self.searchText = searchText
        self.category = category
    }

    public func apply(to materials: [Material]) -> [Material] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return materials.filter { material in
            let matchesCategory = category == nil || material.category == category
            let matchesSearch = needle.isEmpty || material.name.lowercased().contains(needle)
            return matchesCategory && matchesSearch
        }
    }

    /// Distinct categories present in the catalog, in first-seen order — mirrors the web
    /// picker building its chip row from `Array(new Set(materials.map(m => m.category)))`.
    public static func categories(in materials: [Material]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for material in materials where !seen.contains(material.category) {
            seen.insert(material.category)
            ordered.append(material.category)
        }
        return ordered
    }
}

/// Pure "which materials has the user tapped" state for the manual picker, independent
/// of SwiftUI so the max-selectable cap is testable without a device.
public struct MaterialSelectionState: Equatable, Sendable {
    /// Mirrors the backend's `materialIds: z.array(z.string()).min(1).max(50)` bound on
    /// both `/api/activity-recommendations` and `/api/recommendations`.
    public static let maxSelectable = 50

    public private(set) var selectedMaterialIDs: [UUID]

    public init(selectedMaterialIDs: [UUID] = []) {
        self.selectedMaterialIDs = selectedMaterialIDs
    }

    public var canSubmit: Bool { !selectedMaterialIDs.isEmpty }

    public func isSelected(_ id: UUID) -> Bool { selectedMaterialIDs.contains(id) }

    public mutating func toggle(_ id: UUID) {
        if let index = selectedMaterialIDs.firstIndex(of: id) {
            selectedMaterialIDs.remove(at: index)
        } else if selectedMaterialIDs.count < Self.maxSelectable {
            selectedMaterialIDs.append(id)
        }
    }

    public mutating func remove(_ id: UUID) {
        selectedMaterialIDs.removeAll { $0 == id }
    }

    public func recommendationRequest(childAge: Int, requestId: String? = nil) -> ActivityRecommendationRequest {
        let clampedAge = CreateAge.clampToBackendRange(childAge)
        return ActivityRecommendationRequest(
            materialIds: selectedMaterialIDs,
            childAge: clampedAge,
            requestId: requestId ?? Self.dedupeKey(materialIDs: selectedMaterialIDs, childAge: clampedAge)
        )
    }

    /// Mirrors the web results page's retry-safe idempotency key (`${ids.join(",")}:age${age}`),
    /// so a retried request doesn't double-count against the free daily recommendation limit.
    public static func dedupeKey(materialIDs: [UUID], childAge: Int) -> String {
        let sorted = materialIDs.map(\.uuidString).sorted().joined(separator: ",")
        return "\(sorted):age\(childAge)"
    }
}

/// Ports the create-results page's client-side filter chips (`FILTERS` in
/// `src/app/create/results/page.tsx`) — the backend does not support server-side
/// filtering of recommendation matches.
public enum CreateResultsFilter: String, CaseIterable, Equatable, Sendable {
    case all, quick, easy, family

    public var title: String {
        switch self {
        case .all: "All"
        case .quick: "Quick"
        case .easy: "Easy"
        case .family: "Family"
        }
    }

    public func matches(_ match: ActivityMatch) -> Bool {
        switch self {
        case .all: true
        case .quick: match.activity.timeMinutes <= 20
        case .easy: match.activity.difficulty == .easy
        case .family: match.activity.ageRanges.contains(.family)
        }
    }
}
