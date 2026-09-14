import ScrapLabModels
import SwiftUI

struct AuthSheetView: View {
    @Bindable var session: SessionStore
    @Bindable var entitlements: EntitlementsStore
    @Bindable var router: AppRouter
    let onAuthenticated: () -> Void

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var otp = ""
    @State private var childName = ""
    @State private var childAge = 6
    @State private var isWorking = false
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x5) {
                header

                if let message {
                    Text(message)
                        .font(SLFont.callout)
                        .foregroundStyle(SLColor.bodyText)
                        .padding(SLSpacing.x3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SLColor.cream100, in: RoundedRectangle(cornerRadius: SLRadius.card))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(SLFont.callout)
                        .foregroundStyle(SLColor.coralText)
                        .padding(SLSpacing.x3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SLColor.coral.opacity(0.10), in: RoundedRectangle(cornerRadius: SLRadius.card))
                }

                switch mode {
                case .signIn, .signUp:
                    credentialsFields
                    primaryAuthButton
                    secondaryAuthButtons
                case .verifyOTP(let email):
                    otpFields(email: email)
                case .onboarding:
                    onboardingFields
                case .passwordReset:
                    resetFields
                }
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(SLColor.pageBackground)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { router.cancelAuthentication() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Image(systemName: mode.systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(SLColor.primary)
            Text(mode.heading)
                .font(SLFont.title)
                .foregroundStyle(SLColor.ink)
            Text(mode.body)
                .font(SLFont.body)
                .foregroundStyle(SLColor.bodyText)
        }
    }

    private var credentialsFields: some View {
        VStack(spacing: SLSpacing.x3) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .scrapLabField()
            SecureField("Password", text: $password)
                .textContentType(mode == .signIn ? .password : .newPassword)
                .scrapLabField()
        }
    }

    private var primaryAuthButton: some View {
        Button(mode == .signIn ? "Sign in" : "Create account") {
            Task { await submitCredentials() }
        }
        .buttonStyle(.scrapLab(.hero))
        .disabled(isWorking)
        .overlay { if isWorking { ProgressView().tint(.white) } }
    }

    private var secondaryAuthButtons: some View {
        VStack(spacing: SLSpacing.x3) {
            Button(mode == .signIn ? "Need an account? Sign up" : "Already have an account? Sign in") {
                clearMessages()
                mode = mode == .signIn ? .signUp : .signIn
            }
            Button("Forgot password?") {
                clearMessages()
                mode = .passwordReset
            }
        }
        .font(SLFont.caption)
        .foregroundStyle(SLColor.mutedText)
        .frame(maxWidth: .infinity)
    }

    private func otpFields(email: String) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x4) {
            Text("Code sent to \(email)")
                .font(SLFont.callout)
                .foregroundStyle(SLColor.bodyText)
            TextField("6-digit code", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .scrapLabField()
            Button("Confirm email") { Task { await verifyOTP(email: email) } }
                .buttonStyle(.scrapLab(.hero))
                .disabled(isWorking)
            Button("Back to sign in") { mode = .signIn; clearMessages() }
                .font(SLFont.caption)
                .foregroundStyle(SLColor.mutedText)
                .frame(maxWidth: .infinity)
        }
    }

    private var onboardingFields: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x4) {
            TextField("Kid name (optional)", text: $childName)
                .scrapLabField()
            Stepper("Age: \(childAge)", value: $childAge, in: OnboardingChildProfileBuilder.allowedAgeRange)
                .font(SLFont.body)
            Button("Finish setup") { Task { await finishOnboarding() } }
                .buttonStyle(.scrapLab(.hero))
                .disabled(isWorking)
            Button("Skip for now") { finishAuthenticatedFlow() }
                .font(SLFont.caption)
                .foregroundStyle(SLColor.mutedText)
                .frame(maxWidth: .infinity)
        }
    }

    private var resetFields: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x4) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .scrapLabField()
            Button("Send reset email") { Task { await sendReset() } }
                .buttonStyle(.scrapLab(.hero))
                .disabled(isWorking)
            Button("Back") { mode = .signIn; clearMessages() }
                .font(SLFont.caption)
                .foregroundStyle(SLColor.mutedText)
                .frame(maxWidth: .infinity)
        }
    }

    private func submitCredentials() async {
        clearMessages()
        isWorking = true
        defer { isWorking = false }
        do {
            let credentials = try AuthCredentials(email: email, password: password)
            switch mode {
            case .signIn:
                try await session.signIn(credentials: credentials)
                finishAuthenticatedFlow()
            case .signUp:
                let signedIn = try await session.signUp(credentials: credentials)
                if signedIn {
                    mode = .onboarding
                    message = "Account created. Add your first kid profile, or skip for now."
                } else {
                    mode = .verifyOTP(email: credentials.email)
                    message = "Check your email for the 6-digit confirmation code."
                }
            default:
                break
            }
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func verifyOTP(email: String) async {
        clearMessages()
        isWorking = true
        defer { isWorking = false }
        do {
            let code = try OTPCode(otp)
            try await session.verifySignUpOTP(email: email, code: code)
            mode = .onboarding
            message = "Email confirmed. Add your first kid profile, or skip for now."
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func finishOnboarding() async {
        clearMessages()
        isWorking = true
        defer { isWorking = false }
        do {
            try await session.createInitialChildProfile(name: childName, age: childAge, baseURL: AppEnvironment.apiBaseURL)
            finishAuthenticatedFlow()
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func sendReset() async {
        clearMessages()
        isWorking = true
        defer { isWorking = false }
        do {
            try await session.sendPasswordReset(email: email)
            message = "If that account exists, Supabase sent a password reset email."
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func finishAuthenticatedFlow() {
        onAuthenticated()
        router.replayPendingLinkAfterAuthentication()
        router.presentedSheet = nil
    }

    private func clearMessages() {
        message = nil
        errorMessage = nil
    }

    private func displayMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Try again."
    }
}

private enum AuthMode: Equatable {
    case signIn
    case signUp
    case verifyOTP(email: String)
    case onboarding
    case passwordReset

    var title: String {
        switch self {
        case .signIn: "Sign in"
        case .signUp: "Sign up"
        case .verifyOTP: "Confirm email"
        case .onboarding: "Set up household"
        case .passwordReset: "Reset password"
        }
    }

    var heading: String {
        switch self {
        case .signIn: "Welcome back"
        case .signUp: "Create your ScrapLab account"
        case .verifyOTP: "Check your email"
        case .onboarding: "Who are you building for?"
        case .passwordReset: "Reset your password"
        }
    }

    var body: String {
        switch self {
        case .signIn: "Sign in to save builds, manage your household, and unlock Plus features."
        case .signUp: "Use email and password. ScrapLab confirms new accounts with a 6-digit email code so App Review and real families do not get stuck in Safari."
        case .verifyOTP: "Enter the 6-digit code from Supabase to confirm the account."
        case .onboarding: "Add one kid profile so recommendations can tune age and difficulty."
        case .passwordReset: "We'll send a Supabase reset email if the account exists."
        }
    }

    var systemImage: String {
        switch self {
        case .signIn: "person.crop.circle"
        case .signUp: "person.badge.plus"
        case .verifyOTP: "envelope.badge"
        case .onboarding: "figure.2.and.child.holdinghands"
        case .passwordReset: "key"
        }
    }
}

private extension View {
    func scrapLabField() -> some View {
        padding(SLSpacing.x4)
            .font(SLFont.body)
            .foregroundStyle(SLColor.ink)
            .background(SLColor.fieldFill, in: RoundedRectangle(cornerRadius: SLRadius.card))
    }
}
