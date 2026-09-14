import Foundation

/// `Activity` only stores a raw `estimatedCleanupMinutes` integer — there is no
/// `cleanup_level` enum on activities in the backend schema (that field only exists on
/// `ProjectWithMaterials`, backed by the `CleanupLevel` type declared in Models.swift).
/// These thresholds are a native-only judgment call for the Reality Indicators row
/// (spec §4.4), not a ported web value.
extension CleanupLevel {
    public var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    public static func from(estimatedCleanupMinutes minutes: Int) -> CleanupLevel {
        switch minutes {
        case ..<6: .low
        case 6..<16: .medium
        default: .high
        }
    }
}
