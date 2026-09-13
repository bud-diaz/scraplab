import Foundation
import Testing
@testable import ScrapLabModels

@Test func progressOutboxEnqueuesAttemptsRemovesAndClearsEntries() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "scraplab-progress-outbox-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = BuildProgressOutboxStore(fileURL: directory.appending(path: "outbox.json"))
    let buildId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    #expect(try store.load().isEmpty)
    let entry = try store.enqueue(buildId: buildId, request: UpdateBuildProgressRequest(completionStatus: nil, currentStep: 3), now: now)
    #expect(entry.buildId == buildId)
    #expect(entry.request.currentStep == 3)
    #expect(entry.attemptCount == 0)
    #expect(try store.load() == [entry])

    try store.markAttempted(entry.id)
    let attempted = try #require(store.load().first)
    #expect(attempted.attemptCount == 1)

    try store.remove(entry.id)
    #expect(try store.load().isEmpty)

    _ = try store.enqueue(buildId: buildId, request: UpdateBuildProgressRequest(completionStatus: .completed, currentStep: 4), now: now)
    try store.clear()
    #expect(try store.load().isEmpty)
}

@Test func progressOutboxRejectsEmptyPatchLikeBackendRoute() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "scraplab-progress-outbox-empty-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = BuildProgressOutboxStore(fileURL: directory.appending(path: "outbox.json"))

    #expect(throws: BuildProgressOutboxError.emptyPatch) {
        _ = try store.enqueue(buildId: UUID(), request: UpdateBuildProgressRequest())
    }
}

@Test func offlineReadPolicyPrefersCacheOnlyWhenOfflineWithCachedData() {
    #expect(OfflineReadPolicy.defaultPolicy(for: .offline, hasCachedValue: true) == .cacheOnly)
    #expect(OfflineReadPolicy.defaultPolicy(for: .offline, hasCachedValue: false) == .networkOnly)
    #expect(OfflineReadPolicy.defaultPolicy(for: .unknown, hasCachedValue: true) == .cacheThenNetwork)
    #expect(OfflineReadPolicy.defaultPolicy(for: .unknown, hasCachedValue: false) == .networkThenCache)
    #expect(OfflineReadPolicy.defaultPolicy(for: .online, hasCachedValue: true) == .networkThenCache)
}

@Test func networkReachabilityProviderBoundaryCanBeFakedBeforeNWPathMonitorWiring() async {
    let provider: any NetworkReachabilityProviding = StaticNetworkReachabilityProvider(.offline)
    #expect(await provider.currentState == .offline)
}
