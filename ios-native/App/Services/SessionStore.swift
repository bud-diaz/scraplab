import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

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

/// Boundary implemented by the Supabase adapter. It must return refreshed tokens, not cached ones.
protocol AppAuthSessionAdapter: Sendable {
    func currentSession() async throws -> AppSession?
    func signIn(credentials: AuthCredentials) async throws -> AppSession
    func signUp(credentials: AuthCredentials) async throws -> AppSession?
    func verifySignUpOTP(email: String, code: OTPCode) async throws -> AppSession
    func sendPasswordReset(email: String) async throws
    func session(from callbackURL: URL) async throws -> AppSession
    func signOut() async throws
}

struct UnconfiguredAuthSessionAdapter: AppAuthSessionAdapter {
    func currentSession() async throws -> AppSession? { nil }
    func signIn(credentials: AuthCredentials) async throws -> AppSession { throw AuthSessionAdapterError.unconfigured }
    func signUp(credentials: AuthCredentials) async throws -> AppSession? { throw AuthSessionAdapterError.unconfigured }
    func verifySignUpOTP(email: String, code: OTPCode) async throws -> AppSession { throw AuthSessionAdapterError.unconfigured }
    func sendPasswordReset(email: String) async throws { throw AuthSessionAdapterError.unconfigured }
    func session(from callbackURL: URL) async throws -> AppSession { throw AuthSessionAdapterError.unconfigured }
    func signOut() async throws {}
}

enum AuthSessionAdapterError: Error, LocalizedError, Equatable {
    case unconfigured

    var errorDescription: String? { "Supabase is not configured in this build yet." }
}

@MainActor @Observable
final class SessionStore: SessionStoreProtocol {
    private(set) var phase: SessionPhase = .loading
    private let adapter: any AppAuthSessionAdapter

    init(adapter: any AppAuthSessionAdapter = UnconfiguredAuthSessionAdapter()) {
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

    @discardableResult
    func signIn(credentials: AuthCredentials) async throws -> SessionUser {
        let session = try await adapter.signIn(credentials: credentials)
        phase = .authenticated(session.user)
        return session.user
    }

    /// Returns `true` when Supabase produced a session immediately. When email
    /// confirmation is required this returns `false` and the UI should ask for OTP.
    @discardableResult
    func signUp(credentials: AuthCredentials) async throws -> Bool {
        if let session = try await adapter.signUp(credentials: credentials) {
            phase = .authenticated(session.user)
            return true
        }
        return false
    }

    @discardableResult
    func verifySignUpOTP(email: String, code: OTPCode) async throws -> SessionUser {
        let session = try await adapter.verifySignUpOTP(email: email, code: code)
        phase = .authenticated(session.user)
        return session.user
    }

    func sendPasswordReset(email: String) async throws {
        try await adapter.sendPasswordReset(email: email)
    }

    @discardableResult
    func handleAuthCallback(_ url: URL) async throws -> SessionUser {
        let session = try await adapter.session(from: url)
        phase = .authenticated(session.user)
        return session.user
    }

    func createInitialChildProfile(name: String?, age: Int, baseURL: URL) async throws {
        let request = try OnboardingChildProfileBuilder.request(name: name, age: age)
        guard let token = await currentAccessToken() else { throw APIError.unauthorized(message: "Sign in to finish setup.", body: nil) }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        let _: ChildProfileResponse = try await client.send(Endpoints.childProfiles, body: request, as: ChildProfileResponse.self)
    }

    func signOut() async {
        try? await adapter.signOut()
        phase = .guest
    }
}
