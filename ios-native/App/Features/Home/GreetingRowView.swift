import SwiftUI

struct GreetingRowView: View {
    @Bindable var session: SessionStore

    var body: some View {
        HStack(spacing: SLSpacing.x3) {
            Circle()
                .fill(SLColor.primary)
                .frame(width: 44, height: 44)
                .overlay(Text(initial).font(SLFont.headline).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(SLFont.callout).foregroundStyle(SLColor.bodyText)
                Text("Let's build something.").font(SLFont.title).foregroundStyle(SLColor.ink)
            }
            Spacer()
            // Bell links to /challenges on the web; Challenges is Phase 6 work, so this
            // stays a plain icon rather than a button that pretends to go somewhere.
            Image(systemName: "bell").font(.title3).foregroundStyle(SLColor.mutedText)
        }
    }

    private var localPart: String? {
        guard case .authenticated(let user) = session.phase, let email = user.email else { return nil }
        return email.split(separator: "@").first.map(String.init)
    }

    private var initial: String {
        localPart?.first.map { String($0).uppercased() } ?? "S"
    }

    private var greeting: String {
        localPart.map { "Hello, \($0)" } ?? "Hello"
    }
}
