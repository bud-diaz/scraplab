import Foundation
import Observation
import ScrapLabAPI
import ScrapLabModels
import UIKit

enum ScanPhase: Equatable {
    case idle
    case scanning
    case detected([DetectedMaterial])
    case planGate(message: String)
    case failed(message: String)
}

/// Owns `POST /api/scan-materials`. Unlike `CreateResultsStore`, this route requires both
/// auth (`requireAuth`) and a Plus entitlement (`canUsePhotoScan`), so a missing token
/// fails locally before ever hitting the network, and a real 403 still surfaces the same
/// upgrade messaging in case the local session state is stale.
@MainActor @Observable
final class ScanStore {
    private(set) var phase: ScanPhase = .idle
    private(set) var previewImageData: Data?

    private let baseURL: URL
    private let session: SessionStore

    init(baseURL: URL, session: SessionStore) {
        self.baseURL = baseURL
        self.session = session
    }

    func upload(_ image: UIImage) async {
        guard let prepared = PhotoUploadPreparer.prepare(image) else {
            phase = .failed(message: "Could not read that photo. Try another.")
            return
        }
        previewImageData = prepared.data
        await upload(data: prepared.data, mimeType: prepared.mimeType)
    }

    func reset() {
        phase = .idle
        previewImageData = nil
    }

    private func upload(data: Data, mimeType: String) async {
        phase = .scanning
        do {
            try ScanUploadPolicy.validate(byteCount: data.count, mimeType: mimeType)
        } catch {
            phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "That photo can't be uploaded.")
            return
        }
        guard let token = await session.currentAccessToken() else {
            phase = .failed(message: "Sign in to scan materials.")
            return
        }
        let client = APIClient(baseURL: baseURL, tokenProvider: { token })
        var multipart = MultipartFormData()
        multipart.addFile(name: ScanUploadPolicy.fieldName, filename: "scan.jpg", mimeType: mimeType, data: data)
        do {
            let response: ScanResult = try await client.send(Endpoints.scanMaterials, multipart: multipart)
            phase = .detected(response.detectedMaterials)
        } catch {
            if case APIError.planGate(_, let message, _) = error {
                phase = .planGate(message: message ?? "Photo scan requires ScrapLab Plus.")
            } else if case APIError.unauthorized = error {
                phase = .failed(message: "Your session expired. Sign in again to scan materials.")
            } else {
                phase = .failed(message: (error as? LocalizedError)?.errorDescription ?? "Scan failed. Check your connection and try again.")
            }
        }
    }
}
