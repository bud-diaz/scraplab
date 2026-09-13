import Foundation
import Testing
@testable import ScrapLabModels

@Test(arguments: [
    ("Cut two small fins", StepIllustrationAction.cut),
    ("Snip the antenna slot", StepIllustrationAction.cut),
    ("Roll the paper into a tube", StepIllustrationAction.roll),
    ("Fold the base", StepIllustrationAction.fold),
    ("Secure the fins with tape", StepIllustrationAction.tape),
    ("Attach the wheels", StepIllustrationAction.tape),
    ("Glue on the eyes", StepIllustrationAction.glue),
    ("Paint a bright backdrop", StepIllustrationAction.decorate),
    ("Poke a hole for the antenna", StepIllustrationAction.thread),
    ("Thread yarn through", StepIllustrationAction.thread),
    ("Tie a knot", StepIllustrationAction.tie),
    ("Launch and test your rocket", StepIllustrationAction.launch),
    ("Admire your finished craft", StepIllustrationAction.fallback),
])
func stepIllustrationKeywordMatcherMirrorsWebOrdering(title: String, expected: StepIllustrationAction) {
    #expect(StepIllustrationAction(stepTitle: title) == expected)
}

@Test func stepIllustrationMatcherKeepsFirstOrderedAction() {
    #expect(StepIllustrationAction(stepTitle: "Cut and roll the cardboard") == .cut)
    #expect(StepIllustrationAction(stepTitle: "Tape then glue the seam") == .tape)
}

@Test func entitlementGateAllowsPlusForEveryFeature() {
    let access = AccessInfo(
        plan: .plus,
        limits: AccessLimits(dailyRecommendations: nil, photoScan: true, childProfiles: nil, savedProjects: nil),
        usage: AccessUsage(recommendationsToday: 500)
    )

    for feature in EntitlementFeature.allCases {
        #expect(EntitlementGate.evaluate(feature, access: access, currentCount: 999) == .allowed)
    }
}

@Test func entitlementGateEnforcesFreePlanFeatureLocksAndLimits() {
    let access = AccessInfo(
        plan: .free,
        limits: AccessLimits(dailyRecommendations: 3, photoScan: false, childProfiles: 1, savedProjects: 10),
        usage: AccessUsage(recommendationsToday: 3)
    )

    #expect(EntitlementGate.evaluate(.photoScan, access: access) == .upgradeRequired(feature: .photoScan))
    #expect(EntitlementGate.evaluate(.mysteryBuild, access: access) == .upgradeRequired(feature: .mysteryBuild))
    #expect(EntitlementGate.evaluate(.householdStaples, access: access) == .upgradeRequired(feature: .householdStaples))
    #expect(EntitlementGate.evaluate(.premiumContent, access: access) == .upgradeRequired(feature: .premiumContent))
    #expect(EntitlementGate.evaluate(.dailyRecommendations, access: access) == .limitReached(feature: .dailyRecommendations, current: 3, limit: 3))
    #expect(EntitlementGate.evaluate(.childProfiles, access: access, currentCount: 0) == .allowed)
    #expect(EntitlementGate.evaluate(.childProfiles, access: access, currentCount: 1) == .limitReached(feature: .childProfiles, current: 1, limit: 1))
    #expect(EntitlementGate.evaluate(.savedProjects, access: access, currentCount: 10) == .limitReached(feature: .savedProjects, current: 10, limit: 10))
}

@Test func scanUploadPolicyMatchesBackendContract() throws {
    #expect(ScanUploadPolicy.fieldName == "image")
    #expect(ScanUploadPolicy.maxImageBytes == 5 * 1024 * 1024)
    #expect(ScanUploadPolicy.allowedMimeTypes == ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"])

    try ScanUploadPolicy.validate(byteCount: 1, mimeType: "image/jpeg")
    try ScanUploadPolicy.validate(byteCount: ScanUploadPolicy.maxImageBytes, mimeType: "image/heic")

    #expect(throws: ScanUploadPolicy.ValidationError.empty) {
        try ScanUploadPolicy.validate(byteCount: 0, mimeType: "image/png")
    }
    #expect(throws: ScanUploadPolicy.ValidationError.tooLarge(bytes: ScanUploadPolicy.maxImageBytes + 1, limit: ScanUploadPolicy.maxImageBytes)) {
        try ScanUploadPolicy.validate(byteCount: ScanUploadPolicy.maxImageBytes + 1, mimeType: "image/png")
    }
    #expect(throws: ScanUploadPolicy.ValidationError.unsupportedMimeType("image/gif")) {
        try ScanUploadPolicy.validate(byteCount: 128, mimeType: "image/gif")
    }
}

@Test func activityCategoryThemeAssignsOneEmojiPerCategoryWithNoDecorativePalette() {
    for category in ActivityCategory.allCases {
        #expect(!ActivityCategoryTheme.emoji(for: category).isEmpty)
    }
    #expect(ActivityCategoryTheme.emoji(for: .engineering) == "🔧")
    #expect(ActivityCategoryTheme.emoji(for: .pretendPlay) == "🎭")
    #expect(Set(ActivityCategory.allCases.map(ActivityCategoryTheme.emoji(for:))).count == ActivityCategory.allCases.count)
}

@Test func projectDisplayThemePortsWebSlugMapWithoutInventingRows() {
    #expect(ProjectDisplayTheme.theme(for: "cardboard-rocket-ship").emoji == "🚀")
    #expect(ProjectDisplayTheme.theme(for: "bottle-cap-robot").backgroundToken == "walnut-700")
    #expect(ProjectDisplayTheme.theme(for: "unknown-slug") == .fallback)
    #expect(ProjectDisplayTheme.theme(for: "unknown-slug").emoji == "🎨")
}

@Test(arguments: [
    ("scraplab://explore/cardboard-rocket-ship", NativeDeepLink.explore(slug: "cardboard-rocket-ship"), false),
    ("scraplab:/explore/cardboard-rocket-ship", NativeDeepLink.explore(slug: "cardboard-rocket-ship"), false),
    ("scraplab://projects/11111111-1111-1111-1111-111111111111", NativeDeepLink.project(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!), true),
    ("scraplab:/projects/11111111-1111-1111-1111-111111111111", NativeDeepLink.project(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!), true),
    ("scraplab://build/22222222-2222-2222-2222-222222222222", NativeDeepLink.build(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!), true),
    ("scraplab://upgrade", NativeDeepLink.upgrade, true),
    ("scraplab:/auth-callback", NativeDeepLink.authCallback, false),
])
func nativeDeepLinkParserCoversPlannedRoutes(rawURL: String, expected: NativeDeepLink, requiresAuthentication: Bool) throws {
    let url = try #require(URL(string: rawURL))
    let link = try #require(NativeDeepLink(url: url))
    #expect(link == expected)
    #expect(link.requiresAuthentication == requiresAuthentication)
}

@Test func nativeDeepLinkParserRejectsForeignMalformedAndExtraPathRoutes() {
    #expect(NativeDeepLink(url: URL(string: "https://scraplab.app/explore/test")!) == nil)
    #expect(NativeDeepLink(url: URL(string: "scraplab://build/not-a-uuid")!) == nil)
    #expect(NativeDeepLink(url: URL(string: "scraplab://projects/11111111-1111-1111-1111-111111111111/extra")!) == nil)
    #expect(NativeDeepLink(url: URL(string: "scraplab://checkout")!) == nil)
}
