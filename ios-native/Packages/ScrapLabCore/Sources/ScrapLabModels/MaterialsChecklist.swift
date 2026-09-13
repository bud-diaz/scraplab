import Foundation

/// One row in a project's materials checklist, flattened from `ProjectMaterialWithMaterial`
/// so the UI does not have to reach through two levels of optionality.
public struct MaterialsChecklistItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let materialId: UUID
    public let name: String
    public let icon: String?
    public let required: Bool
    public let quantityNote: String?

    public init(id: UUID, materialId: UUID, name: String, icon: String?, required: Bool, quantityNote: String?) {
        self.id = id
        self.materialId = materialId
        self.name = name
        self.icon = icon
        self.required = required
        self.quantityNote = quantityNote
    }
}

/// Pure "what materials does this project need, and which has the user checked off"
/// state, independent of SwiftUI so the completion/premium-gate rules stay testable.
public struct MaterialsChecklistState: Equatable, Sendable {
    public let items: [MaterialsChecklistItem]
    public private(set) var checkedMaterialIDs: Set<UUID>

    public init(items: [MaterialsChecklistItem], checkedMaterialIDs: Set<UUID> = []) {
        self.items = items
        self.checkedMaterialIDs = checkedMaterialIDs
    }

    public static func from(_ project: ProjectWithMaterials) -> MaterialsChecklistState {
        MaterialsChecklistState(items: project.projectMaterials.map {
            MaterialsChecklistItem(id: $0.id, materialId: $0.materialId, name: $0.material.name, icon: $0.material.icon, required: $0.required, quantityNote: $0.quantityNote)
        })
    }

    public var requiredItems: [MaterialsChecklistItem] { items.filter(\.required) }
    public var optionalItems: [MaterialsChecklistItem] { items.filter { !$0.required } }

    public func isChecked(_ item: MaterialsChecklistItem) -> Bool { checkedMaterialIDs.contains(item.materialId) }

    /// All required materials are checked. Optional materials never gate this.
    public var hasEverythingRequired: Bool {
        !requiredItems.isEmpty && requiredItems.allSatisfy { checkedMaterialIDs.contains($0.materialId) }
    }

    public mutating func toggle(_ item: MaterialsChecklistItem) {
        if checkedMaterialIDs.contains(item.materialId) {
            checkedMaterialIDs.remove(item.materialId)
        } else {
            checkedMaterialIDs.insert(item.materialId)
        }
    }

    /// Pre-checks whatever the household already has on hand, e.g. from `GET /api/household-inventory`.
    public mutating func markOnHand(materialIDs: Set<UUID>) {
        checkedMaterialIDs.formUnion(items.map(\.materialId).filter(materialIDs.contains))
    }
}
