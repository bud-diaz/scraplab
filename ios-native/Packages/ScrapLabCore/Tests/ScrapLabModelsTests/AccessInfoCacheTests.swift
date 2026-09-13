import Foundation
import Testing
@testable import ScrapLabModels

@Test func accessInfoCachePersistsLoadsAndClearsAccessInfo() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "scraplab-access-cache-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache = AccessInfoCache(fileURL: directory.appending(path: "access.json"))
    let access = AccessInfo(
        plan: .plus,
        limits: AccessLimits(dailyRecommendations: nil, photoScan: true, childProfiles: nil, savedProjects: nil),
        usage: AccessUsage(recommendationsToday: 2)
    )

    #expect(try cache.load() == nil)
    try cache.save(access)
    #expect(try cache.load() == access)
    try cache.clear()
    #expect(try cache.load() == nil)
}

@Test func accessInfoCacheSurfacesCorruptDataInsteadOfSilentlyDowngrading() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "scraplab-access-cache-corrupt-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let fileURL = directory.appending(path: "access.json")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("not-json".utf8).write(to: fileURL)
    let cache = AccessInfoCache(fileURL: fileURL)

    #expect(throws: DecodingError.self) {
        _ = try cache.load()
    }
}
