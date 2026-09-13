import Foundation
import Observation

struct SessionUser: Equatable, Sendable {
    let id: UUID
    let email: String?
}

struct AppSession: Equatable, Sendable {
    let user: SessionUser
    let accessToken: String
}

enum SessionPhase: Equatable {
    case loading
    case guest
    case authenticated(SessionUser)
}

@MainActor
protocol SessionStoreProtocol: AnyObject {
    var phase: SessionPhase { get }
    var isAuthenticated: Bool { get }
    func currentAccessToken() async -> String?
    func restore() async
    func signOut() async
}

/// Boundary implemented by a future Supabase adapter. It must return refreshed tokens, not cached ones.
protocol AuthSessionAdapter: Sendable {
    func currentSession() async throws -> AppSession?
    func signOut() async throws
}

struct UnconfiguredAuthSessionAdapter: AuthSessionAdapter {
    func currentSession() async throws -> AppSession? { nil }
    func signOut() async throws {}
}

@MainActor @Observable
final class SessionStore: SessionStoreProtocol {
    private(set) var phase: SessionPhase = .loading
    private let adapter: any AuthSessionAdapter

    init(adapter: any AuthSessionAdapter = UnconfiguredAuthSessionAdapter()) {
        self.adapter = adapter
    }

    var isAuthenticated: Bool {
        if case .authenticated = phase { return true }
        return false
    }

    func currentAccessToken() async -> String? {
        try? await adapter.currentSession()?.accessToken
    }

    func restore() async {
        do {
            phase = try await adapter.currentSession().map { .authenticated($0.user) } ?? .guest
        } catch {
            phase = .guest
        }
    }

    func signOut() async {
        try? await adapter.signOut()
        phase = .guest
    }
}
