import Foundation
import Observation

struct EntitlementSnapshot: Codable, Equatable, Sendable {
    enum Plan: String, Codable, Sendable { case free, plus }

    struct Limits: Codable, Equatable, Sendable {
        let dailyRecommendations: Int?
        let photoScan: Bool
        let childProfiles: Int?
        let savedProjects: Int?
    }

    struct Usage: Codable, Equatable, Sendable {
        let recommendationsToday: Int
    }

    let plan: Plan
    let limits: Limits
    let usage: Usage
}

enum EntitlementsPhase: Equatable {
    case idle
    case loading
    case loaded(EntitlementSnapshot)
    case failed(message: String)
}

@MainActor
protocol EntitlementsStoreProtocol: AnyObject {
    var phase: EntitlementsPhase { get }
    func refresh(accessToken: String) async
    func reset()
}

protocol EntitlementsLoading: Sendable {
    func accessInfo(accessToken: String) async throws -> EntitlementSnapshot
}

struct UnconfiguredEntitlementsLoader: EntitlementsLoading {
    func accessInfo(accessToken: String) async throws -> EntitlementSnapshot {
        throw URLError(.unsupportedURL)
    }
}

@MainActor @Observable
final class EntitlementsStore: EntitlementsStoreProtocol {
    private(set) var phase: EntitlementsPhase = .idle
    private let loader: any EntitlementsLoading

    init(loader: any EntitlementsLoading = UnconfiguredEntitlementsLoader()) {
        self.loader = loader
    }

    func refresh(accessToken: String) async {
        guard !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            phase = .failed(message: "An access token is required.")
            return
        }
        phase = .loading
        do {
            phase = .loaded(try await loader.accessInfo(accessToken: accessToken))
        } catch {
            phase = .failed(message: error.localizedDescription)
        }
    }

    func reset() { phase = .idle }
}
