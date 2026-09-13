import Foundation
import ScrapLabModels
import Supabase

struct SupabaseAuthSessionAdapter: AppAuthSessionAdapter {
    private let client: SupabaseClient
    private let authCallbackURL = URL(string: "scraplab://auth-callback")!

    init(supabaseURL: URL, anonKey: String) {
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey
        )
    }

    func currentSession() async throws -> AppSession? {
        do {
            return try await appSession(from: client.auth.session)
        } catch {
            return nil
        }
    }

    func signIn(credentials: AuthCredentials) async throws -> AppSession {
        try await appSession(from: client.auth.signIn(email: credentials.email, password: credentials.password))
    }

    func signUp(credentials: AuthCredentials) async throws -> AppSession? {
        let response = try await client.auth.signUp(
            email: credentials.email,
            password: credentials.password,
            redirectTo: authCallbackURL
        )
        guard let session = response.session else { return nil }
        return try await appSession(from: session)
    }

    func verifySignUpOTP(email: String, code: OTPCode) async throws -> AppSession {
        let response = try await client.auth.verifyOTP(email: email, token: code.value, type: .signup)
        guard let session = response.session else {
            throw SupabaseAuthSessionError.missingSessionAfterOTP
        }
        return try await appSession(from: session)
    }

    func sendPasswordReset(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty, normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            throw NativeAuthValidationError.invalidEmail
        }
        try await client.auth.resetPasswordForEmail(normalizedEmail, redirectTo: authCallbackURL)
    }

    func session(from callbackURL: URL) async throws -> AppSession {
        try await appSession(from: client.auth.session(from: callbackURL))
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    private func appSession(from session: Supabase.Session) async throws -> AppSession {
        AppSession(
            user: SessionUser(id: session.user.id, email: session.user.email),
            accessToken: session.accessToken
        )
    }
}

enum SupabaseAuthSessionError: Error, LocalizedError, Equatable {
    case missingSessionAfterOTP

    var errorDescription: String? {
        switch self {
        case .missingSessionAfterOTP:
            "Supabase confirmed the code but did not return a session. Try signing in."
        }
    }
}
