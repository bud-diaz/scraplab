import Foundation
import ScrapLabModels
import UIKit

/// Thin UIKit wrapper around the pure `PhotoCapturePolicy` numbers: downscale to the
/// policy's 1600px long edge, encode at 0.8 quality, and recompress at 0.6 only if the
/// first pass still exceeds the 5 MB cap — matching the Capacitor `quality: 80` behavior
/// this replaces so the user practically never sees a 413 from `/api/scan-materials`.
enum PhotoUploadPreparer {
    struct Prepared {
        let data: Data
        let mimeType: String
    }

    static func prepare(_ image: UIImage) -> Prepared? {
        let originalPixels = PixelDimensions(
            width: Int((image.size.width * image.scale).rounded()),
            height: Int((image.size.height * image.scale).rounded())
        )
        let target = PhotoCapturePolicy.resizedDimensions(for: originalPixels)
        let resized = resized(image, to: CGSize(width: target.width, height: target.height))

        guard var data = resized.jpegData(compressionQuality: PhotoCapturePolicy.preferredJPEGQuality) else { return nil }
        let quality = PhotoCapturePolicy.jpegQuality(afterEncodingByteCount: data.count)
        if quality != PhotoCapturePolicy.preferredJPEGQuality, let recompressed = resized.jpegData(compressionQuality: quality) {
            data = recompressed
        }
        return Prepared(data: data, mimeType: "image/jpeg")
    }

    private static func resized(_ image: UIImage, to size: CGSize) -> UIImage {
        let currentPixelSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        guard size.width > 0, size.height > 0, currentPixelSize != size else { return image }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
