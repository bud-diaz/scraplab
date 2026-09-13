import Foundation
import Testing
@testable import ScrapLab

@Test func parsesGuestExploreDeepLink() throws {
    let url = try #require(URL(string: "scraplab://explore/cardboard-rocket"))
    let link = try #require(DeepLink(url: url))

    #expect(link == .explore(slug: "cardboard-rocket"))
    #expect(link.requiresAuthentication == false)
}

@Test func parsesAuthenticatedBuildDeepLink() throws {
    let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let url = try #require(URL(string: "scraplab://build/\(id.uuidString)"))
    let link = try #require(DeepLink(url: url))

    #expect(link == .build(id: id))
    #expect(link.requiresAuthentication)
}

@Test func rejectsMalformedOrForeignDeepLinks() {
    #expect(DeepLink(url: URL(string: "https://scraplab.app/explore/test")!) == nil)
    #expect(DeepLink(url: URL(string: "scraplab://build/not-a-uuid")!) == nil)
    #expect(DeepLink(url: URL(string: "scraplab://unknown")!) == nil)
}
