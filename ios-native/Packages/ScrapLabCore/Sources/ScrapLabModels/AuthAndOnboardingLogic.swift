import Foundation

public enum NativeAuthValidationError: Equatable, LocalizedError, Sendable {
    case missingEmail
    case invalidEmail
    case missingPassword
    case weakPassword(minimumCharacters: Int)
    case invalidOTP
    case invalidChildAge(range: ClosedRange<Int>)

    public var errorDescription: String? {
        switch self {
        case .missingEmail: "Email is required"
        case .invalidEmail: "Enter a valid email address"
        case .missingPassword: "Password is required"
        case .weakPassword(let minimumCharacters): "Password must be at least \(minimumCharacters) characters"
        case .invalidOTP: "Enter the 6-digit code from your email"
        case .invalidChildAge(let range): "Child age must be between \(range.lowerBound) and \(range.upperBound)"
        }
    }
}

public struct AuthCredentials: Equatable, Sendable {
    public static let minimumPasswordCharacters = 8

    public let email: String
    public let password: String

    public init(email: String, password: String) throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else { throw NativeAuthValidationError.missingEmail }
        guard Self.looksLikeEmail(normalizedEmail) else { throw NativeAuthValidationError.invalidEmail }
        guard !password.isEmpty else { throw NativeAuthValidationError.missingPassword }
        guard password.count >= Self.minimumPasswordCharacters else {
            throw NativeAuthValidationError.weakPassword(minimumCharacters: Self.minimumPasswordCharacters)
        }
        self.email = normalizedEmail
        self.password = password
    }

    private static func looksLikeEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, let local = parts.first, let domain = parts.last else { return false }
        return !local.isEmpty && domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }
}

public struct OTPCode: Equatable, Sendable {
    public let value: String

    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 6, trimmed.allSatisfy(\.isNumber) else {
            throw NativeAuthValidationError.invalidOTP
        }
        value = trimmed
    }
}

public enum AuthFlowState: Equatable, Sendable {
    case signedOut
    case signingIn
    case signingUp
    case awaitingOTP(email: String)
    case resettingPassword(email: String)
    case authenticated(userId: UUID, email: String)
    case failed(message: String)
}

public enum AuthFlowEvent: Equatable, Sendable {
    case startSignIn
    case startSignUp
    case otpSent(email: String)
    case startPasswordReset(email: String)
    case authenticated(userId: UUID, email: String)
    case fail(String)
    case signOut
    case cancel
}

public enum AuthFlowReducer {
    public static func reduce(_ state: AuthFlowState, event: AuthFlowEvent) -> AuthFlowState {
        switch event {
        case .startSignIn: .signingIn
        case .startSignUp: .signingUp
        case .otpSent(let email): .awaitingOTP(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        case .startPasswordReset(let email): .resettingPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        case .authenticated(let userId, let email): .authenticated(userId: userId, email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        case .fail(let message): .failed(message: message)
        case .signOut, .cancel: .signedOut
        }
    }
}

public struct AuthSession: Equatable, Sendable {
    public let userId: UUID
    public let email: String
    public let accessToken: String

    public init(userId: UUID, email: String, accessToken: String) {
        self.userId = userId
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.accessToken = accessToken
    }
}

public protocol AuthSessionAdapter: Sendable {
    func currentSession() async throws -> AuthSession?
    func signIn(credentials: AuthCredentials) async throws -> AuthSession
    func signUp(credentials: AuthCredentials) async throws
    func verifySignUpOTP(email: String, code: OTPCode) async throws -> AuthSession
    func sendPasswordReset(email: String) async throws
    func signOut() async throws
}

public enum OnboardingChildProfileBuilder {
    public static let allowedAgeRange = 0...18

    public static func request(name: String?, age: Int) throws -> ChildProfileRequest {
        guard allowedAgeRange.contains(age) else {
            throw NativeAuthValidationError.invalidChildAge(range: allowedAgeRange)
        }
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ChildProfileRequest(name: trimmedName?.isEmpty == true ? nil : trimmedName, age: age)
    }
}
