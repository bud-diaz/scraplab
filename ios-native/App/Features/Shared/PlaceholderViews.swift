import SwiftUI

struct GuestSignInNudge: View {
    let title: String
    let message: String
    let onSignIn: () -> Void

    var body: some View {
        SLEmptyState(title: title, message: message, systemImage: "person.crop.circle.badge.plus", actionTitle: "Sign in", action: onSignIn)
            .navigationTitle(title)
    }
}

struct PlaceholderDestination: View {
    let title: String
    let message: String

    var body: some View {
        SLEmptyState(title: title, message: message)
            .navigationTitle(title)
            .background(SLColor.pageBackground)
    }
}
