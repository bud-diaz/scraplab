import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels

enum ChildProfilesPhase: Equatable {
    case loading
    case loaded
    case failed(message: String)
}

@MainActor @Observable
final class ChildProfilesStore {
    private(set) var childProfiles: [ChildProfile] = []
    private(set) var phase: ChildProfilesPhase = .loading
    private(set) var actionError: String?

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func loadIfNeeded() async {
        guard phase == .loading, childProfiles.isEmpty else { return }
        await reload()
    }

    func reload() async {
        phase = .loading
        guard let token = await session.currentAccessToken() else {
            childProfiles = []
            phase = .loaded
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        do {
            let response: ChildProfilesResponse = try await client.send(Endpoints.childProfiles)
            childProfiles = response.childProfiles
            phase = .loaded
        } catch {
            phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Couldn't load kid profiles.")
        }
    }

    /// `at limit` mirrors `isWithinLimit(plan, 'childProfiles', count)`: free=1, plus=10.
    func isAtLimit(access: EntitlementSnapshot?) -> Bool {
        guard let access, access.plan == .free else { return false }
        return childProfiles.count >= (access.limits.childProfiles ?? Int.max)
    }

    func add(name: String?, age: Int) async {
        actionError = nil
        guard let token = await session.currentAccessToken() else {
            actionError = "Sign in to add a kid profile."
            return
        }
        do {
            let request = try OnboardingChildProfileBuilder.request(name: name, age: age)
            let client = APIClient(baseURL: baseURL, tokenProvider: { token })
            let response: ChildProfileResponse = try await client.send(Endpoints.createChildProfile, body: request)
            childProfiles.append(response.childProfile)
        } catch {
            actionError = describeAddError(error)
        }
    }

    func update(_ profile: ChildProfile, name: String?, age: Int) async {
        actionError = nil
        guard let token = await session.currentAccessToken() else {
            actionError = "Sign in to edit this kid profile."
            return
        }
        do {
            let request = try OnboardingChildProfileBuilder.request(name: name, age: age)
            let client = APIClient(baseURL: baseURL, tokenProvider: { token })
            let response: ChildProfileResponse = try await client.send(Endpoints.updateChildProfile(profile.id), body: request)
            if let index = childProfiles.firstIndex(where: { $0.id == profile.id }) {
                childProfiles[index] = response.childProfile
            }
        } catch {
            actionError = (error as? LocalizedError)?.errorDescription ?? "Couldn't update this kid profile."
        }
    }

    func delete(_ profile: ChildProfile) async {
        guard let token = await session.currentAccessToken() else { return }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        childProfiles.removeAll { $0.id == profile.id }
        do {
            let _: EmptyResponse = try await client.send(Endpoints.deleteChildProfile(profile.id))
        } catch {
            if !childProfiles.contains(where: { $0.id == profile.id }) {
                childProfiles.append(profile)
            }
        }
    }

    private func describeAddError(_ error: Error) -> String {
        if case APIError.limitReached(let message, _) = error {
            return message ?? "You've reached your kid profile limit. Upgrade to ScrapLab Plus for up to 10."
        }
        return (error as? LocalizedError)?.errorDescription ?? "Couldn't add this kid profile."
    }
}
