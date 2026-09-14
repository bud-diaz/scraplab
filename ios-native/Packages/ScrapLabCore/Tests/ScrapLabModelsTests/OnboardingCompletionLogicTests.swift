import Testing
@testable import ScrapLabModels

@Test func ageBandRangesCoverThreeThroughTenWithoutGapsOrOverlaps() {
    #expect(AgeBand.littleBuilder.ageRange == 3...5)
    #expect(AgeBand.juniorMaker.ageRange == 6...8)
    #expect(AgeBand.masterCrafter.ageRange == 9...10)
    #expect(AgeBand.allCases.count == 3)
}

@Test func ageBandDefaultAgeIsTheLowerBoundOfItsRange() {
    for band in AgeBand.allCases {
        #expect(band.defaultAge == band.ageRange.lowerBound)
    }
}

@Test func shouldShowOnboardingIsTrueOnlyBeforeItHasBeenSeen() {
    #expect(OnboardingCompletionPolicy.shouldShowOnboarding(hasSeenOnboarding: false) == true)
    #expect(OnboardingCompletionPolicy.shouldShowOnboarding(hasSeenOnboarding: true) == false)
}
