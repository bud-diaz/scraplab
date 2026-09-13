import Foundation
import Testing
@testable import ScrapLabModels

@Test func authCredentialsNormalizeEmailAndRequireUsablePassword() throws {
    let credentials = try AuthCredentials(email: " Parent@Example.COM ", password: "crafting123")
    #expect(credentials.email == "parent@example.com")
    #expect(credentials.password == "crafting123")

    #expect(throws: NativeAuthValidationError.missingEmail) {
        _ = try AuthCredentials(email: " ", password: "crafting123")
    }
    #expect(throws: NativeAuthValidationError.invalidEmail) {
        _ = try AuthCredentials(email: "parent", password: "crafting123")
    }
    #expect(throws: NativeAuthValidationError.missingPassword) {
        _ = try AuthCredentials(email: "parent@example.com", password: "")
    }
    #expect(throws: NativeAuthValidationError.weakPassword(minimumCharacters: 8)) {
        _ = try AuthCredentials(email: "parent@example.com", password: "short")
    }
}

@Test func otpCodeRequiresExactlySixDigits() throws {
    #expect(try OTPCode(" 123456 ").value == "123456")
    #expect(throws: NativeAuthValidationError.invalidOTP) { _ = try OTPCode("12345") }
    #expect(throws: NativeAuthValidationError.invalidOTP) { _ = try OTPCode("1234567") }
    #expect(throws: NativeAuthValidationError.invalidOTP) { _ = try OTPCode("12A456") }
}

@Test func authFlowReducerCoversSignUpOTPResetAndSignOut() {
    let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    var state = AuthFlowReducer.reduce(.signedOut, event: .startSignUp)
    #expect(state == .signingUp)

    state = AuthFlowReducer.reduce(state, event: .otpSent(email: " Parent@Example.COM "))
    #expect(state == .awaitingOTP(email: "parent@example.com"))

    state = AuthFlowReducer.reduce(state, event: .authenticated(userId: userId, email: " Parent@Example.COM "))
    #expect(state == .authenticated(userId: userId, email: "parent@example.com"))

    state = AuthFlowReducer.reduce(state, event: .signOut)
    #expect(state == .signedOut)

    state = AuthFlowReducer.reduce(state, event: .startPasswordReset(email: " Parent@Example.COM "))
    #expect(state == .resettingPassword(email: "parent@example.com"))

    state = AuthFlowReducer.reduce(state, event: .cancel)
    #expect(state == .signedOut)
}

@Test func authSessionAdapterFakeCoversPhaseTwoBoundary() async throws {
    let userId = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    let adapter = FakeAuthSessionAdapter(session: AuthSession(userId: userId, email: " Parent@Example.COM ", accessToken: "token"))
    let credentials = try AuthCredentials(email: "parent@example.com", password: "crafting123")
    let code = try OTPCode("123456")

    #expect(try await adapter.currentSession()?.email == "parent@example.com")
    #expect(try await adapter.signIn(credentials: credentials).accessToken == "token")
    try await adapter.signUp(credentials: credentials)
    #expect(try await adapter.verifySignUpOTP(email: " Parent@Example.COM ", code: code).userId == userId)
    try await adapter.sendPasswordReset(email: "parent@example.com")
    try await adapter.signOut()
}

private struct FakeAuthSessionAdapter: AuthSessionAdapter {
    let session: AuthSession?

    func currentSession() async throws -> AuthSession? { session }
    func signIn(credentials: AuthCredentials) async throws -> AuthSession { try #require(session) }
    func signUp(credentials: AuthCredentials) async throws {}
    func verifySignUpOTP(email: String, code: OTPCode) async throws -> AuthSession { try #require(session) }
    func sendPasswordReset(email: String) async throws {}
    func signOut() async throws {}
}

@Test func onboardingChildProfileBuilderValidatesAgeAndTrimsName() throws {
    try expectEncodedObject(try OnboardingChildProfileBuilder.request(name: "  Luna  ", age: 6)) { object in
        #expect(object["name"] as? String == "Luna")
        #expect(object["age"] as? Int == 6)
    }

    try expectEncodedObject(try OnboardingChildProfileBuilder.request(name: "   ", age: 0)) { object in
        #expect(object["name"] is NSNull)
        #expect(object["age"] as? Int == 0)
    }

    #expect(throws: NativeAuthValidationError.invalidChildAge(range: 0...18)) {
        _ = try OnboardingChildProfileBuilder.request(name: nil, age: -1)
    }
    #expect(throws: NativeAuthValidationError.invalidChildAge(range: 0...18)) {
        _ = try OnboardingChildProfileBuilder.request(name: nil, age: 19)
    }
}

private func expectEncodedObject<T: Encodable>(_ value: T, checks: ([String: Any]) throws -> Void) throws {
    let data = try ModelCoding.encoder().encode(value)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    try checks(object)
}
