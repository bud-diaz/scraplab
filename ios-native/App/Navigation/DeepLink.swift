import Foundation

enum DeepLink: Equatable {
    case explore(slug: String)
    case project(id: UUID)
    case build(id: UUID)
    case upgrade
    case authCallback

    var requiresAuthentication: Bool {
        switch self {
        case .explore, .authCallback: false
        case .project, .build, .upgrade: true
        }
    }

    init?(url: URL) {
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
