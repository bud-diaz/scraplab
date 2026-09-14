import ScrapLabAPI
import ScrapLabModels
import SwiftUI

/// A bookmark button that saves/unsaves an activity's linked project to the Library.
/// Deliberately a standalone view, layered as a `ZStack` sibling over a `NavigationLink`-
/// wrapped `ProjectCardView` at each call site — never nested inside `ProjectCardView`
/// itself, per the exact nested-interactive-control bug already fixed once in this
/// codebase (`SavedProjectCardView`'s unsave button vs. its wrapping `NavigationLink`).
///
/// Only shows for signed-in users on activities with a linked project (`projectId`) — call
/// sites should gate construction on `session.isAuthenticated && activity.projectId != nil`.
struct ProjectSaveButton: View {
    let projectId: UUID
    let session: SessionStore

    private enum SaveState: Equatable {
        case unsaved
        case saving
        /// `savedProjectID` is nil only on a 409-conflict response (already saved by an
        /// earlier action elsewhere), which doesn't hand back the saved-project row id
        /// needed to unsave — the button shows as saved but isn't interactive in that
        /// case; full unsave is still always available from the Library tab.
        case saved(savedProjectID: UUID?)
    }

    @State private var saveState: SaveState = .unsaved

    var body: some View {
        Button {
            Task { await toggleSave() }
        } label: {
            Group {
                if saveState == .saving {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isSaved ? SLColor.primary : SLColor.mutedText)
                }
            }
            .frame(width: 28, height: 28)
            .background(Color.white, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(saveState == .saving || (isSaved && savedProjectID == nil))
        .accessibilityLabel(isSaved ? "Remove from library" : "Save to library")
    }

    private var isSaved: Bool {
        if case .saved = saveState { return true }
        return false
    }

    private var savedProjectID: UUID? {
        if case .saved(let id) = saveState { return id }
        return nil
    }

    private func toggleSave() async {
        guard let token = await session.currentAccessToken() else { return }
        let client = APIClient(baseURL: AppEnvironment.apiBaseURL, tokenProvider: { token })
        switch saveState {
        case .saving:
            return
        case .unsaved:
            saveState = .saving
            do {
                let response: SavedProjectResponse = try await client.send(Endpoints.saveProject, body: SaveProjectRequest(projectId: projectId))
                saveState = .saved(savedProjectID: response.savedProject.id)
            } catch {
                if case APIError.conflict = error {
                    saveState = .saved(savedProjectID: nil)
                } else {
                    saveState = .unsaved
                }
            }
        case .saved(let savedProjectID):
            guard let savedProjectID else { return }
            saveState = .saving
            do {
                let _: EmptyResponse = try await client.send(Endpoints.deleteSavedProject(savedProjectID))
                saveState = .unsaved
            } catch {
                saveState = .saved(savedProjectID: savedProjectID)
            }
        }
    }
}
