import Testing
@testable import ScrapLabModels

@Test func cleanupLevelBucketsMinutesIntoLowMediumHigh() {
    #expect(CleanupLevel.from(estimatedCleanupMinutes: 0) == .low)
    #expect(CleanupLevel.from(estimatedCleanupMinutes: 5) == .low)
    #expect(CleanupLevel.from(estimatedCleanupMinutes: 6) == .medium)
    #expect(CleanupLevel.from(estimatedCleanupMinutes: 15) == .medium)
    #expect(CleanupLevel.from(estimatedCleanupMinutes: 16) == .high)
    #expect(CleanupLevel.from(estimatedCleanupMinutes: 60) == .high)
}
