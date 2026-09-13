import Foundation
import SwiftUI

struct HomeView: View {
    @Bindable var router: AppRouter
    @Bindable var session: SessionStore
    @State private var store: HomeStore

    init(router: AppRouter, session: SessionStore, baseURL: URL) {
        self.router = router
        self.session = session
        _store = State(initialValue: HomeStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SLSpacing.x6) {
                GreetingRowView(session: session)

                if !session.isAuthenticated {
                    signInNudge
                }

                WeeklyProgressView(summary: store.weeklyProgress, isSignedIn: session.isAuthenticated)

                QuickNavRowView(router: router)

                if !store.featuredActivities.isEmpty {
                    SuggestedForYouView(
                        activities: store.featuredActivities,
                        onSeeAll: { router.selectedTab = .browse },
                        onSelect: { activity in
                            router.selectedTab = .browse
                            router.browsePath = [.explore(activity.slug)]
                        }
                    )
                }

                ContinueBuildingView(entries: store.continueBuilding) { project in
                    router.selectedTab = .buildLog
                    router.buildLogPath = [.build(project.id)]
                }

                HouseholdStaplesView(
                    staples: store.staples,
                    onEdit: {
                        router.selectedTab = .create
                        router.createPath = [.manual]
                    },
                    onFindBuilds: { materialIDs in
                        router.selectedTab = .create
                        router.createPath = [.results(materialIDs: materialIDs, childAge: 7)]
                    }
                )

                Divider()
                Button("Open foundation demo") { router.homePath.append(.foundation) }
                    .buttonStyle(.scrapLab(.secondary, size: .compact))
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("ScrapLab")
        .background(SLColor.pageBackground.ignoresSafeArea())
        .task { await store.loadIfNeeded() }
    }

    private var signInNudge: some View {
        Button {
            router.presentedSheet = .signIn
        } label: {
            Text("Sign in for personalized recommendations and saved builds.")
                .font(SLFont.callout)
                .foregroundStyle(SLColor.bodyText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SLSpacing.x3)
                .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.card))
        }
        .buttonStyle(.plain)
    }
}
