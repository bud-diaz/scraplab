import Foundation
import SwiftUI

struct ProfileView: View {
    @Bindable var session: SessionStore
    @Bindable var entitlements: EntitlementsStore
    @Bindable var router: AppRouter
    let baseURL: URL
    @State private var childProfilesStore: ChildProfilesStore
    @State private var staplesStore: HouseholdStaplesStore

    init(baseURL: URL, session: SessionStore, entitlements: EntitlementsStore, router: AppRouter) {
        self.baseURL = baseURL
        self.session = session
        self.entitlements = entitlements
        self.router = router
        _childProfilesStore = State(initialValue: ChildProfilesStore(baseURL: baseURL, session: session))
        _staplesStore = State(initialValue: HouseholdStaplesStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x5) {
                header
                KidsSectionView(store: childProfilesStore, isAtLimit: childProfilesStore.isAtLimit(access: currentSnapshot))
                if isPlus {
                    StaplesSectionView(store: staplesStore)
                } else {
                    UpgradeCard(title: "Household Staples", message: "Save your always-on-hand materials so builds can use them automatically.") {
                        router.presentedSheet = .upgrade
                    }
                }
                navLinks
                DeleteAccountSectionView(session: session, entitlements: entitlements, baseURL: baseURL)
                Button("Sign out") { Task { await session.signOut() } }
                    .font(SLFont.callout)
                    .foregroundStyle(SLColor.mutedText)
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("Profile")
        .background(SLColor.pageBackground)
        .task {
            await childProfilesStore.loadIfNeeded()
            await staplesStore.loadIfNeeded()
        }
    }

    private var currentSnapshot: EntitlementSnapshot? {
        if case .loaded(let snapshot) = entitlements.phase { return snapshot }
        return nil
    }

    private var isPlus: Bool {
        currentSnapshot?.plan == .plus
    }

    private var header: some View {
        HStack(spacing: SLSpacing.x3) {
            Image(systemName: "person.crop.circle.fill").font(.system(size: 44)).foregroundStyle(SLColor.mutedText)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Household").font(SLFont.title2).foregroundStyle(SLColor.ink)
                if case .authenticated(let user) = session.phase, let email = user.email {
                    Text(email).font(SLFont.caption).foregroundStyle(SLColor.bodyText)
                }
            }
            Spacer()
            NavigationLink(value: ProfileRoute.subscription) {
                MetadataChip(label: isPlus ? "Plus ✓" : "Upgrade", systemImage: isPlus ? nil : "sparkles")
            }
        }
    }

    private var navLinks: some View {
        VStack(spacing: 0) {
            NavigationLink(value: ProfileRoute.subscription) { navRow("Manage Subscription", icon: "sparkles") }
            NavigationLink(value: ProfileRoute.challenges) { navRow("Challenges", icon: "trophy") }
            NavigationLink(value: ProfileRoute.privacyPolicy) { navRow("Privacy Policy", icon: "hand.raised") }
        }
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }

    private func navRow(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(SLColor.primary).frame(width: 24)
            Text(title).font(SLFont.body).foregroundStyle(SLColor.ink)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(SLColor.mutedText)
        }
        .padding(SLSpacing.x4)
        .contentShape(Rectangle())
    }
}
