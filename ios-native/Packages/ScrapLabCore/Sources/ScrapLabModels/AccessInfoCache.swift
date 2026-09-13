import Foundation

public struct AccessInfoCache: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL, encoder: JSONEncoder = ModelCoding.encoder(), decoder: JSONDecoder = ModelCoding.decoder()) {
        self.fileURL = fileURL
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() throws -> AccessInfo? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(AccessInfo.self, from: data)
    }

    public func save(_ accessInfo: AccessInfo) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(accessInfo)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
