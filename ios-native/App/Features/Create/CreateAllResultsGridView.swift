import ScrapLabModels
import SwiftUI

/// Pushed from the results carousel's trailing "See More!" card once there are more than
/// 10 matches — the full set, in the original 2-column grid the carousel replaced, rather
/// than making someone swipe through dozens of cards one at a time.
struct CreateAllResultsGridView: View {
    let matches: [ActivityMatch]
    let session: SessionStore

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SLSpacing.x3) {
                ForEach(matches, id: \.activity.id) { match in
                    ZStack(alignment: .topLeading) {
                        NavigationLink(value: CreateRoute.activity(slug: match.activity.slug)) {
                            ProjectCardView(activity: match.activity, matchLabel: match.matchLabel, layout: .compact)
                        }
                        .buttonStyle(.plain)

                        if let projectId = match.activity.projectId, session.isAuthenticated {
                            ProjectSaveButton(projectId: projectId, session: session)
                                .padding(SLSpacing.x1)
                        }
                    }
                }
            }
            .padding(SLSpacing.x4)
        }
        .navigationTitle("All Builds")
        .navigationBarTitleDisplayMode(.inline)
        .background(SLColor.pageBackground)
    }
}
