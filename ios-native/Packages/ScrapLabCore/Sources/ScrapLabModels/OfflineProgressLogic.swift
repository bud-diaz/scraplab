import Foundation

public struct BuildProgressOutboxEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let buildId: UUID
    public let request: UpdateBuildProgressRequest
    public let enqueuedAt: Date
    public var attemptCount: Int

    public init(id: UUID = UUID(), buildId: UUID, request: UpdateBuildProgressRequest, enqueuedAt: Date = Date(), attemptCount: Int = 0) {
        self.id = id
        self.buildId = buildId
        self.request = request
        self.enqueuedAt = enqueuedAt
        self.attemptCount = attemptCount
    }

}

public enum BuildProgressOutboxError: Equatable, LocalizedError, Sendable {
    case emptyPatch

    public var errorDescription: String? {
        switch self {
        case .emptyPatch: "Provide completionStatus and/or currentStep"
        }
    }
}

public struct BuildProgressOutboxStore: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, encoder: JSONEncoder = ModelCoding.encoder(), decoder: JSONDecoder = ModelCoding.decoder()) {
        self.fileURL = fileURL
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() throws -> [BuildProgressOutboxEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([BuildProgressOutboxEntry].self, from: data)
    }

    @discardableResult
    public func enqueue(buildId: UUID, request: UpdateBuildProgressRequest, now: Date = Date()) throws -> BuildProgressOutboxEntry {
        guard request.completionStatus != nil || request.currentStep != nil else {
            throw BuildProgressOutboxError.emptyPatch
        }
        var entries = try load()
        let entry = BuildProgressOutboxEntry(buildId: buildId, request: request, enqueuedAt: now)
        entries.append(entry)
        try save(entries)
        return entry
    }

    public func markAttempted(_ entryId: UUID) throws {
        var entries = try load()
        guard let index = entries.firstIndex(where: { $0.id == entryId }) else { return }
        entries[index].attemptCount += 1
        try save(entries)
    }

    public func remove(_ entryId: UUID) throws {
        var entries = try load()
        entries.removeAll { $0.id == entryId }
        try save(entries)
    }

    public func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    private func save(_ entries: [BuildProgressOutboxEntry]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: [.atomic])
    }
}

public enum NetworkReachabilityState: Equatable, Sendable {
    case unknown
    case online
    case offline
}

public protocol NetworkReachabilityProviding: Sendable {
    var currentState: NetworkReachabilityState { get async }
}

public struct StaticNetworkReachabilityProvider: NetworkReachabilityProviding {
    private let state: NetworkReachabilityState

    public init(_ state: NetworkReachabilityState) {
        self.state = state
    }

    public var currentState: NetworkReachabilityState { get async { state } }
}

public enum OfflineReadPolicy: Equatable, Sendable {
    case networkOnly
    case networkThenCache
    case cacheThenNetwork
    case cacheOnly

    public static func defaultPolicy(for reachability: NetworkReachabilityState, hasCachedValue: Bool) -> Self {
        switch (reachability, hasCachedValue) {
        case (.offline, true): .cacheOnly
        case (.offline, false): .networkOnly
        case (.unknown, true): .cacheThenNetwork
        case (.unknown, false), (.online, _): .networkThenCache
        }
    }
}
