import Foundation

public enum Plan: String, Codable, CaseIterable, Sendable { case free, plus }
public enum CleanupLevel: String, Codable, CaseIterable, Sendable { case low, medium, high }
public enum SupervisionLevel: String, Codable, CaseIterable, Sendable {
    case independent
    case checkIn = "check_in"
    case adultAssist = "adult_assist"
    case fullSupervision = "full_supervision"

    /// Normalizes legacy activity labels conservatively. Unknown labels return nil.
    public static func normalizedActivityLabel(_ rawValue: String) -> Self? {
        switch rawValue {
        case "independent": .independent
        case "some-help": .adultAssist
        case "adult-needed": .fullSupervision
        default: nil
        }
    }
}
public enum Difficulty: String, Codable, CaseIterable, Sendable { case easy, medium, advanced }
public enum CompletionStatus: String, Codable, CaseIterable, Sendable { case started, completed, abandoned }
public enum InventorySource: String, Codable, CaseIterable, Sendable { case manual, detected, saved }
public enum MatchType: String, Codable, CaseIterable, Sendable { case exact, close, fallback }
public enum ActivityCategory: String, Codable, CaseIterable, Sendable {
    case cooperative, science, engineering, storytelling
    case pretendPlay = "pretend-play"
    case seasonal, puzzle, art
}
public enum ActivityDifficulty: String, Codable, CaseIterable, Sendable { case easy, medium, hard, adaptive }
public enum ActivityEnergyLevel: String, Codable, CaseIterable, Sendable {
    case calm, moderate, active
    case chaoticGoblin = "chaotic-goblin"
}
public enum ActivityAgeRange: String, Codable, CaseIterable, Sendable {
    case threeToFive = "3-5"
    case sixToEight = "6-8"
    case nineToTwelve = "9-12"
    case thirteenPlus = "13+"
    case family
}

public struct UserProfile: Codable, Equatable, Sendable {
    public let id: UUID; public let email: String; public let createdAt: Date; public let plan: Plan
    public init(id: UUID, email: String, createdAt: Date, plan: Plan) { self.id = id; self.email = email; self.createdAt = createdAt; self.plan = plan }
}

public struct ChildProfile: Codable, Equatable, Sendable {
    public let id: UUID; public let userId: UUID; public let name: String?; public let age: Int; public let createdAt: Date
    public init(id: UUID, userId: UUID, name: String?, age: Int, createdAt: Date) { self.id = id; self.userId = userId; self.name = name; self.age = age; self.createdAt = createdAt }
}

public struct Material: Codable, Equatable, Sendable {
    public let id: UUID; public let name: String; public let aliases: [String]; public let category: String; public let icon: String?; public let createdAt: Date
    public init(id: UUID, name: String, aliases: [String], category: String, icon: String?, createdAt: Date) { self.id = id; self.name = name; self.aliases = aliases; self.category = category; self.icon = icon; self.createdAt = createdAt }
}

public struct BuildStep: Codable, Equatable, Sendable {
    public let step: Int; public let instruction: String; public let tip: String?; public let safetyNote: String?
    public init(step: Int, instruction: String, tip: String? = nil, safetyNote: String? = nil) { self.step = step; self.instruction = instruction; self.tip = tip; self.safetyNote = safetyNote }
}

public struct Project: Codable, Equatable, Sendable {
    public let id: UUID; public let title: String; public let slug: String; public let description: String
    public let ageMin: Int; public let ageMax: Int; public let timeMinutes: Int
    public let cleanupLevel: CleanupLevel; public let supervisionLevel: SupervisionLevel; public let difficulty: Difficulty
    public let safetyNotes: [String]; public let instructions: [BuildStep]; public let imageUrl: String?
    public let premiumOnly: Bool; public let createdAt: Date

    public init(id: UUID, title: String, slug: String, description: String, ageMin: Int, ageMax: Int, timeMinutes: Int, cleanupLevel: CleanupLevel, supervisionLevel: SupervisionLevel, difficulty: Difficulty, safetyNotes: [String], instructions: [BuildStep], imageUrl: String?, premiumOnly: Bool, createdAt: Date) {
        self.id = id; self.title = title; self.slug = slug; self.description = description; self.ageMin = ageMin; self.ageMax = ageMax; self.timeMinutes = timeMinutes; self.cleanupLevel = cleanupLevel; self.supervisionLevel = supervisionLevel; self.difficulty = difficulty; self.safetyNotes = safetyNotes; self.instructions = instructions; self.imageUrl = imageUrl; self.premiumOnly = premiumOnly; self.createdAt = createdAt
    }
}

public struct ProjectMaterial: Codable, Equatable, Sendable {
    public let id: UUID; public let projectId: UUID; public let materialId: UUID; public let required: Bool; public let quantityNote: String?; public let material: Material?
    public init(id: UUID, projectId: UUID, materialId: UUID, required: Bool, quantityNote: String?, material: Material? = nil) { self.id = id; self.projectId = projectId; self.materialId = materialId; self.required = required; self.quantityNote = quantityNote; self.material = material }
}

/// The required-material variant used by `ProjectWithMaterials`.
public struct ProjectMaterialWithMaterial: Codable, Equatable, Sendable {
    public let id: UUID; public let projectId: UUID; public let materialId: UUID; public let required: Bool; public let quantityNote: String?; public let material: Material
    public init(id: UUID, projectId: UUID, materialId: UUID, required: Bool, quantityNote: String?, material: Material) { self.id = id; self.projectId = projectId; self.materialId = materialId; self.required = required; self.quantityNote = quantityNote; self.material = material }
}

public struct MaterialSubstitution: Codable, Equatable, Sendable {
    public let id: UUID; public let sourceMaterialId: UUID; public let replacementMaterialId: UUID; public let substitutionNotes: String?
    public init(id: UUID, sourceMaterialId: UUID, replacementMaterialId: UUID, substitutionNotes: String?) { self.id = id; self.sourceMaterialId = sourceMaterialId; self.replacementMaterialId = replacementMaterialId; self.substitutionNotes = substitutionNotes }
}

/// The wire shape of `ProjectWithMaterials` is a project with an added `project_materials` field.
public struct ProjectWithMaterials: Codable, Equatable, Sendable {
    public let id: UUID; public let title: String; public let slug: String; public let description: String
    public let ageMin: Int; public let ageMax: Int; public let timeMinutes: Int
    public let cleanupLevel: CleanupLevel; public let supervisionLevel: SupervisionLevel; public let difficulty: Difficulty
    public let safetyNotes: [String]; public let instructions: [BuildStep]; public let imageUrl: String?
    public let premiumOnly: Bool; public let createdAt: Date; public let projectMaterials: [ProjectMaterialWithMaterial]

    public init(project: Project, projectMaterials: [ProjectMaterialWithMaterial]) {
        id = project.id; title = project.title; slug = project.slug; description = project.description
        ageMin = project.ageMin; ageMax = project.ageMax; timeMinutes = project.timeMinutes
        cleanupLevel = project.cleanupLevel; supervisionLevel = project.supervisionLevel; difficulty = project.difficulty
        safetyNotes = project.safetyNotes; instructions = project.instructions; imageUrl = project.imageUrl
        premiumOnly = project.premiumOnly; createdAt = project.createdAt; self.projectMaterials = projectMaterials
    }
}

public struct SavedProject: Codable, Equatable, Sendable {
    public let id: UUID; public let userId: UUID; public let projectId: UUID; public let createdAt: Date; public let project: Project?
    public init(id: UUID, userId: UUID, projectId: UUID, createdAt: Date, project: Project? = nil) { self.id = id; self.userId = userId; self.projectId = projectId; self.createdAt = createdAt; self.project = project }
}

public struct BuildHistory: Codable, Equatable, Sendable {
    public let id: UUID; public let userId: UUID; public let projectId: UUID; public let childProfileId: UUID?
    public let completionStatus: CompletionStatus; public let currentStep: Int; public let startedAt: Date; public let completedAt: Date?; public let project: Project?
    public init(id: UUID, userId: UUID, projectId: UUID, childProfileId: UUID?, completionStatus: CompletionStatus, currentStep: Int, startedAt: Date, completedAt: Date?, project: Project? = nil) { self.id = id; self.userId = userId; self.projectId = projectId; self.childProfileId = childProfileId; self.completionStatus = completionStatus; self.currentStep = currentStep; self.startedAt = startedAt; self.completedAt = completedAt; self.project = project }
}

public struct HouseholdInventory: Codable, Equatable, Sendable {
    public let id: UUID; public let userId: UUID; public let materialId: UUID; public let confidenceScore: Double?
    public let source: InventorySource; public let stapleFlag: Bool; public let updatedAt: Date; public let material: Material?
    public init(id: UUID, userId: UUID, materialId: UUID, confidenceScore: Double?, source: InventorySource, stapleFlag: Bool, updatedAt: Date, material: Material? = nil) { self.id = id; self.userId = userId; self.materialId = materialId; self.confidenceScore = confidenceScore; self.source = source; self.stapleFlag = stapleFlag; self.updatedAt = updatedAt; self.material = material }
}

public struct RecommendationPreferences: Codable, Equatable, Sendable {
    public let maxTimeMinutes: Int?; public let cleanupLevel: CleanupLevel?; public let supervisionLevel: SupervisionLevel?
    public init(maxTimeMinutes: Int? = nil, cleanupLevel: CleanupLevel? = nil, supervisionLevel: SupervisionLevel? = nil) { self.maxTimeMinutes = maxTimeMinutes; self.cleanupLevel = cleanupLevel; self.supervisionLevel = supervisionLevel }
}

public struct RecommendationInput: Codable, Equatable, Sendable {
    public let materialIds: [UUID]; public let childAge: Int; public let preferences: RecommendationPreferences?
    public init(materialIds: [UUID], childAge: Int, preferences: RecommendationPreferences? = nil) { self.materialIds = materialIds; self.childAge = childAge; self.preferences = preferences }
}

public struct ActivityRecommendationRequest: Codable, Equatable, Sendable {
    public let materialIds: [UUID]; public let childAge: Int; public let requestId: String?
    public init(materialIds: [UUID], childAge: Int, requestId: String? = nil) { self.materialIds = materialIds; self.childAge = childAge; self.requestId = requestId }
}

public struct ChildProfileRequest: Codable, Equatable, Sendable {
    public let name: String?; public let age: Int?
    public init(name: String? = nil, age: Int? = nil) { self.name = name; self.age = age }

    private enum CodingKeys: String, CodingKey { case name, age }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(age, forKey: .age)
    }
}

public struct HouseholdInventoryRequest: Codable, Equatable, Sendable {
    public let materialId: UUID?; public let source: InventorySource?; public let stapleFlag: Bool?; public let confidenceScore: Double?
    public init(materialId: UUID? = nil, source: InventorySource? = nil, stapleFlag: Bool? = nil, confidenceScore: Double? = nil) { self.materialId = materialId; self.source = source; self.stapleFlag = stapleFlag; self.confidenceScore = confidenceScore }
}

public struct StartBuildRequest: Codable, Equatable, Sendable {
    public let projectId: UUID; public let childProfileId: UUID?
    public init(projectId: UUID, childProfileId: UUID? = nil) { self.projectId = projectId; self.childProfileId = childProfileId }
}

public struct UpdateBuildProgressRequest: Codable, Equatable, Sendable {
    public let completionStatus: CompletionStatus?; public let currentStep: Int?
    public init(completionStatus: CompletionStatus? = nil, currentStep: Int? = nil) { self.completionStatus = completionStatus; self.currentStep = currentStep }
}

public struct SaveProjectRequest: Codable, Equatable, Sendable {
    public let projectId: UUID
    public init(projectId: UUID) { self.projectId = projectId }
}

public struct SuggestedSubstitution: Codable, Equatable, Sendable {
    public let missingMaterialId: UUID; public let replacementMaterialId: UUID; public let notes: String?
    public init(missingMaterialId: UUID, replacementMaterialId: UUID, notes: String?) { self.missingMaterialId = missingMaterialId; self.replacementMaterialId = replacementMaterialId; self.notes = notes }
}

public struct ProjectRecommendation: Codable, Equatable, Sendable {
    public let projectId: UUID; public let title: String; public let matchType: MatchType; public let matchScore: Double
    public let missingRequiredMaterials: [UUID]; public let availableMaterialsUsed: [UUID]
    public let suggestedSubstitutions: [SuggestedSubstitution]; public let reason: String
    public init(projectId: UUID, title: String, matchType: MatchType, matchScore: Double, missingRequiredMaterials: [UUID], availableMaterialsUsed: [UUID], suggestedSubstitutions: [SuggestedSubstitution], reason: String) { self.projectId = projectId; self.title = title; self.matchType = matchType; self.matchScore = matchScore; self.missingRequiredMaterials = missingRequiredMaterials; self.availableMaterialsUsed = availableMaterialsUsed; self.suggestedSubstitutions = suggestedSubstitutions; self.reason = reason }
}

public struct AccessLimits: Codable, Equatable, Sendable {
    public let dailyRecommendations: Int?; public let photoScan: Bool; public let childProfiles: Int?; public let savedProjects: Int?
    public init(dailyRecommendations: Int?, photoScan: Bool, childProfiles: Int?, savedProjects: Int?) { self.dailyRecommendations = dailyRecommendations; self.photoScan = photoScan; self.childProfiles = childProfiles; self.savedProjects = savedProjects }
}
public struct AccessUsage: Codable, Equatable, Sendable {
    public let recommendationsToday: Int
    public init(recommendationsToday: Int) { self.recommendationsToday = recommendationsToday }
}
public struct AccessInfo: Codable, Equatable, Sendable {
    public let plan: Plan; public let limits: AccessLimits; public let usage: AccessUsage
    public init(plan: Plan, limits: AccessLimits, usage: AccessUsage) { self.plan = plan; self.limits = limits; self.usage = usage }
}

public struct DetectedMaterial: Codable, Equatable, Sendable {
    public let materialId: UUID; public let label: String; public let confidence: Double
    public init(materialId: UUID, label: String, confidence: Double) { self.materialId = materialId; self.label = label; self.confidence = confidence }
}
public struct ScanResult: Codable, Equatable, Sendable {
    public let detectedMaterials: [DetectedMaterial]; public let requiresConfirmation: Bool
    public init(detectedMaterials: [DetectedMaterial], requiresConfirmation: Bool) { self.detectedMaterials = detectedMaterials; self.requiresConfirmation = requiresConfirmation }
}

/// Partial material shape returned by `/api/mystery-materials`, which selects
/// only id/name/icon/category rather than the full `Material` row.
public struct MysteryMaterial: Codable, Equatable, Sendable {
    public let id: UUID; public let name: String; public let icon: String?; public let category: String
    public init(id: UUID, name: String, icon: String?, category: String) { self.id = id; self.name = name; self.icon = icon; self.category = category }
}

public struct AiSuggestion: Codable, Equatable, Sendable {
    public let title: String; public let description: String; public let timeMinutes: Int
    public let cleanupLevel: String; public let supervisionLevel: String; public let materials: [String]; public let steps: [String]
    public init(title: String, description: String, timeMinutes: Int, cleanupLevel: String, supervisionLevel: String, materials: [String], steps: [String]) {
        self.title = title; self.description = description; self.timeMinutes = timeMinutes; self.cleanupLevel = cleanupLevel; self.supervisionLevel = supervisionLevel; self.materials = materials; self.steps = steps
    }
}

public struct ActivityMatch: Codable, Equatable, Sendable {
    public let activity: Activity; public let matchedCount: Int; public let totalRequired: Int; public let matchScore: Double; public let matchLabel: String
    public init(activity: Activity, matchedCount: Int, totalRequired: Int, matchScore: Double, matchLabel: String) {
        self.activity = activity; self.matchedCount = matchedCount; self.totalRequired = totalRequired; self.matchScore = matchScore; self.matchLabel = matchLabel
    }
}

public struct Activity: Codable, Equatable, Sendable {
    public let id: UUID; public let title: String; public let slug: String; public let category: ActivityCategory
    public let oneLiner: String?; public let description: String?; public let ageRanges: [ActivityAgeRange]
    public let difficulty: ActivityDifficulty; public let timeMinutes: Int; public let estimatedCleanupMinutes: Int
    public let attentionSpanFit: String; public let energyLevel: ActivityEnergyLevel; public let soloOrGroup: String
    /// Raw database label; use `normalizedSupervisionLevel` for safety UI.
    public let supervisionLevel: String
    public let environment: [String]; public let materialsRequired: [String]; public let materialsOptional: [String]
    public let scrapTags: [String]; public let themeTags: [String]; public let skillTags: [String]; public let promptType: String
    public let learningAngle: String?; public let expansionPrompts: [String]; public let safetyNotes: [String]
    public let heroImagePrompt: String?; public let premium: Bool; public let featured: Bool; public let seasonal: String?
    public let inventoryFriendly: Bool; public let remixable: Bool; public let createdAt: Date; public let projectId: UUID?

    public var normalizedSupervisionLevel: SupervisionLevel? { SupervisionLevel.normalizedActivityLabel(supervisionLevel) }

    public init(id: UUID, title: String, slug: String, category: ActivityCategory, oneLiner: String?, description: String?, ageRanges: [ActivityAgeRange], difficulty: ActivityDifficulty, timeMinutes: Int, estimatedCleanupMinutes: Int, attentionSpanFit: String, energyLevel: ActivityEnergyLevel, soloOrGroup: String, supervisionLevel: String, environment: [String], materialsRequired: [String], materialsOptional: [String], scrapTags: [String], themeTags: [String], skillTags: [String], promptType: String, learningAngle: String?, expansionPrompts: [String], safetyNotes: [String], heroImagePrompt: String?, premium: Bool, featured: Bool, seasonal: String?, inventoryFriendly: Bool, remixable: Bool, createdAt: Date, projectId: UUID?) {
        self.id = id; self.title = title; self.slug = slug; self.category = category; self.oneLiner = oneLiner; self.description = description; self.ageRanges = ageRanges; self.difficulty = difficulty; self.timeMinutes = timeMinutes; self.estimatedCleanupMinutes = estimatedCleanupMinutes; self.attentionSpanFit = attentionSpanFit; self.energyLevel = energyLevel; self.soloOrGroup = soloOrGroup; self.supervisionLevel = supervisionLevel; self.environment = environment; self.materialsRequired = materialsRequired; self.materialsOptional = materialsOptional; self.scrapTags = scrapTags; self.themeTags = themeTags; self.skillTags = skillTags; self.promptType = promptType; self.learningAngle = learningAngle; self.expansionPrompts = expansionPrompts; self.safetyNotes = safetyNotes; self.heroImagePrompt = heroImagePrompt; self.premium = premium; self.featured = featured; self.seasonal = seasonal; self.inventoryFriendly = inventoryFriendly; self.remixable = remixable; self.createdAt = createdAt; self.projectId = projectId
    }
}

public struct ActivitiesResponse: Codable, Equatable, Sendable { public let activities: [Activity]; public let total: Int }
public struct ActivityResponse: Codable, Equatable, Sendable { public let activity: Activity }
public struct ProjectsResponse: Codable, Equatable, Sendable { public let projects: [ProjectWithMaterials] }
public struct ProjectResponse: Codable, Equatable, Sendable { public let project: ProjectWithMaterials; public let substitutions: [MaterialSubstitution] }
public struct ActivityRecommendationsResponse: Codable, Equatable, Sendable { public let matches: [ActivityMatch]; public let aiSuggestions: [AiSuggestion] }
public struct RecommendationsResponse: Codable, Equatable, Sendable { public let recommendations: [ProjectRecommendation]; public let aiSuggestions: [AiSuggestion] }
public struct HouseholdInventoryResponse: Codable, Equatable, Sendable { public let inventory: [HouseholdInventory] }
public struct HouseholdInventoryItemResponse: Codable, Equatable, Sendable { public let item: HouseholdInventory }
public struct BuildHistoryResponse: Codable, Equatable, Sendable { public let buildHistory: [BuildHistory] }
public struct BuildEntryResponse: Codable, Equatable, Sendable { public let buildEntry: BuildHistory }
public struct SavedProjectsResponse: Codable, Equatable, Sendable { public let savedProjects: [SavedProject] }
public struct SavedProjectResponse: Codable, Equatable, Sendable { public let savedProject: SavedProject }
public struct ChildProfilesResponse: Codable, Equatable, Sendable { public let childProfiles: [ChildProfile] }
public struct ChildProfileResponse: Codable, Equatable, Sendable { public let childProfile: ChildProfile }
public struct MaterialsResponse: Codable, Equatable, Sendable { public let grouped: [String: [Material]]?; public let materials: [Material] }
public struct MysteryMaterialsResponse: Codable, Equatable, Sendable { public let materials: [MysteryMaterial] }

public enum ModelCoding {
    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) { return date }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date: \(value)")
        }
        return decoder
    }

    /// Requests intentionally retain Swift property names because backend request bodies use camelCase.
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
