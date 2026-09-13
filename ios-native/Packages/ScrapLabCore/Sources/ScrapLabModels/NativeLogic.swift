import Foundation

public enum StepIllustrationAction: String, Codable, CaseIterable, Sendable {
    case cut
    case roll
    case fold
    case tape
    case glue
    case decorate
    case thread
    case tie
    case launch
    case fallback

    /// Mirrors the web StepIllustration keyword ordering. The order is intentional:
    /// a title like "Cut and roll" must resolve to `.cut`, not `.roll`.
    public init(stepTitle: String) {
        let normalized = stepTitle.lowercased()
        if normalized.contains(anyOf: ["cut", "snip", "scissor"]) { self = .cut; return }
        if normalized.contains("roll") { self = .roll; return }
        if normalized.contains("fold") { self = .fold; return }
        if normalized.contains(anyOf: ["tape", "secure", "attach"]) { self = .tape; return }
        if normalized.contains("glue") { self = .glue; return }
        if normalized.contains(anyOf: ["decor", "color", "paint", "draw", "backdrop"]) { self = .decorate; return }
        if normalized.contains(anyOf: ["poke", "thread", "hole", "antenn"]) { self = .thread; return }
        if normalized.contains(anyOf: ["tie", "knot"]) { self = .tie; return }
        if normalized.contains(anyOf: ["launch", "test", "try", "stand"]) { self = .launch; return }
        self = .fallback
    }
}

public enum EntitlementFeature: String, Codable, CaseIterable, Sendable {
    case dailyRecommendations
    case photoScan
    case childProfiles
    case savedProjects
    case premiumContent
    case mysteryBuild
    case householdStaples
}

public enum EntitlementDecision: Equatable, Sendable {
    case allowed
    case upgradeRequired(feature: EntitlementFeature)
    case limitReached(feature: EntitlementFeature, current: Int, limit: Int)
}

public enum EntitlementGate {
    public static func evaluate(_ feature: EntitlementFeature, access: AccessInfo, currentCount: Int = 0) -> EntitlementDecision {
        if access.plan == .plus { return .allowed }

        switch feature {
        case .photoScan, .premiumContent, .mysteryBuild, .householdStaples:
            return .upgradeRequired(feature: feature)
        case .dailyRecommendations:
            return limitDecision(feature: feature, current: max(currentCount, access.usage.recommendationsToday), limit: access.limits.dailyRecommendations)
        case .childProfiles:
            return limitDecision(feature: feature, current: currentCount, limit: access.limits.childProfiles)
        case .savedProjects:
            return limitDecision(feature: feature, current: currentCount, limit: access.limits.savedProjects)
        }
    }

    private static func limitDecision(feature: EntitlementFeature, current: Int, limit: Int?) -> EntitlementDecision {
        guard let limit else { return .allowed }
        return current < limit ? .allowed : .limitReached(feature: feature, current: current, limit: limit)
    }

    /// Per-item premium gating, distinct from `evaluate(_:access:)`: an activity or project
    /// only needs an upgrade card when it is itself `premium`/`premiumOnly` and the viewer
    /// is on the free plan, not whenever the free plan lacks the broader feature.
    public static func isPremiumContentLocked(premium: Bool, plan: Plan) -> Bool {
        premium && plan == .free
    }
}

/// Mirrors the two backend route-param validators so the client can fail a bad deep link
/// before firing a network request instead of relying on the server's 404.
public enum RouteSegment {
    private static let safeSegmentCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
    private static let slugCharacters = Set("abcdefghijklmnopqrstuvwxyz0123456789")

    /// Mirrors `isSafeRouteSegment` in `src/lib/validation/identifiers.ts`, used by
    /// `GET /api/activities/[id]`, which resolves by either UUID `id` or `slug`.
    public static func isSafeActivityLookup(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy(safeSegmentCharacters.contains)
    }

    /// Mirrors `resolveProject`'s `SLUG_PATTERN` in `src/lib/projects/resolve.ts`: a project
    /// lookup key must be a UUID or a lowercase, hyphen-separated slug.
    public static func isValidProjectLookup(_ value: String) -> Bool {
        UUID(uuidString: value) != nil || isSlug(value)
    }

    private static func isSlug(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        let segments = value.split(separator: "-", omittingEmptySubsequences: false)
        guard segments.allSatisfy({ !$0.isEmpty }) else { return false }
        return segments.allSatisfy { $0.allSatisfy(slugCharacters.contains) }
    }
}

public enum ScanUploadPolicy {
    public static let fieldName = "image"
    public static let maxImageBytes = 5 * 1024 * 1024
    public static let allowedMimeTypes: Set<String> = ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]

    public enum ValidationError: Equatable, LocalizedError, Sendable {
        case empty
        case tooLarge(bytes: Int, limit: Int)
        case unsupportedMimeType(String)

        public var errorDescription: String? {
            switch self {
            case .empty: "Image file is empty"
            case .tooLarge: "Image exceeds the 5 MB limit"
            case .unsupportedMimeType(let mimeType): "Unsupported image type: \(mimeType.isEmpty ? "unknown" : mimeType)"
            }
        }
    }

    public static func validate(byteCount: Int, mimeType: String) throws {
        if byteCount == 0 { throw ValidationError.empty }
        if byteCount > maxImageBytes { throw ValidationError.tooLarge(bytes: byteCount, limit: maxImageBytes) }
        if !allowedMimeTypes.contains(mimeType) { throw ValidationError.unsupportedMimeType(mimeType) }
    }
}

public enum ProjectDisplayTheme: Equatable, Sendable {
    case known(emoji: String, backgroundToken: String)
    case fallback

    public var emoji: String {
        switch self {
        case .known(let emoji, _): emoji
        case .fallback: "🎨"
        }
    }

    public var backgroundToken: String {
        switch self {
        case .known(_, let backgroundToken): backgroundToken
        case .fallback: "kraft-500"
        }
    }

    public static func theme(for slug: String) -> Self {
        switch slug {
        case "cardboard-rocket-ship": .known(emoji: "🚀", backgroundToken: "builder-500")
        case "bottle-cap-robot": .known(emoji: "🤖", backgroundToken: "walnut-700")
        case "egg-carton-creature": .known(emoji: "🐛", backgroundToken: "kraft-500")
        case "cup-and-string-phone": .known(emoji: "📞", backgroundToken: "orange-500")
        case "cereal-box-puppet-theater": .known(emoji: "🎭", backgroundToken: "walnut-600")
        case "paper-binoculars": .known(emoji: "🔭", backgroundToken: "builder-400")
        case "foil-moon-rocks": .known(emoji: "🌙", backgroundToken: "kraft-400")
        case "marble-ramp": .known(emoji: "⚙️", backgroundToken: "charcoal-700")
        default: .fallback
        }
    }
}

/// Mirrors `src/lib/categoryTheme.ts`: one Soft Lavender tile for every activity
/// category, with the emoji alone carrying category identity. Do not invent a
/// per-category palette here — Leaf/Amber/Coral are reserved for supervision
/// safety and blue/orange for hero/CTA moments, per the design spec.
public enum ActivityCategoryTheme {
    public static let tileBackgroundToken = "cream-100"

    public static func emoji(for category: ActivityCategory) -> String {
        switch category {
        case .engineering: "🔧"
        case .science: "🔬"
        case .art: "🎨"
        case .storytelling: "📖"
        case .pretendPlay: "🎭"
        case .cooperative: "🤝"
        case .puzzle: "🧩"
        case .seasonal: "🍂"
        }
    }
}

public enum NativeDeepLink: Equatable, Sendable {
    case explore(slug: String)
    case project(id: UUID)
    case build(id: UUID)
    case upgrade
    case authCallback

    public var requiresAuthentication: Bool {
        switch self {
        case .explore, .authCallback: false
        case .project, .build, .upgrade: true
        }
    }

    public init?(url: URL) {
        guard url.scheme?.lowercased() == "scraplab" else { return nil }
        var components = url.pathComponents.filter { $0 != "/" }
        if let host = url.host, !host.isEmpty { components.insert(host, at: 0) }

        let lowercased = components.map { $0.lowercased() }
        switch (lowercased.first, lowercased.count) {
        case ("explore", 2):
            self = .explore(slug: components[1])
        case ("projects", 2):
            guard let id = UUID(uuidString: components[1]) else { return nil }
            self = .project(id: id)
        case ("build", 2):
            guard let id = UUID(uuidString: components[1]) else { return nil }
            self = .build(id: id)
        case ("upgrade", 1):
            self = .upgrade
        case ("auth-callback", 1):
            self = .authCallback
        default:
            return nil
        }
    }
}

private extension String {
    func contains(anyOf needles: [String]) -> Bool {
        needles.contains { contains($0) }
    }
}
