import Foundation

public struct PixelDimensions: Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var longestEdge: Int { max(width, height) }
}

public enum PhotoCapturePolicy {
    public static let targetLongestEdge = 1_600
    public static let preferredJPEGQuality = 0.8
    public static let fallbackJPEGQuality = 0.6
    public static let maxUploadBytes = ScanUploadPolicy.maxImageBytes

    public static func resizedDimensions(for original: PixelDimensions) -> PixelDimensions {
        guard original.width > 0, original.height > 0 else { return original }
        let longest = original.longestEdge
        guard longest > targetLongestEdge else { return original }

        let scale = Double(targetLongestEdge) / Double(longest)
        return PixelDimensions(
            width: max(1, Int((Double(original.width) * scale).rounded())),
            height: max(1, Int((Double(original.height) * scale).rounded()))
        )
    }

    public static func jpegQuality(afterEncodingByteCount byteCount: Int) -> Double {
        byteCount > maxUploadBytes ? fallbackJPEGQuality : preferredJPEGQuality
    }
}
