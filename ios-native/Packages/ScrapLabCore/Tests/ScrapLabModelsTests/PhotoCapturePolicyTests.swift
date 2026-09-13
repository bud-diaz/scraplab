import Testing
@testable import ScrapLabModels

@Test func photoCapturePolicyKeepsSmallImagesAtOriginalDimensions() {
    #expect(PhotoCapturePolicy.resizedDimensions(for: PixelDimensions(width: 1200, height: 900)) == PixelDimensions(width: 1200, height: 900))
}

@Test func photoCapturePolicyDownscalesLongestEdgeToSixteenHundredPixels() {
    #expect(PhotoCapturePolicy.resizedDimensions(for: PixelDimensions(width: 4032, height: 3024)) == PixelDimensions(width: 1600, height: 1200))
    #expect(PhotoCapturePolicy.resizedDimensions(for: PixelDimensions(width: 3024, height: 4032)) == PixelDimensions(width: 1200, height: 1600))
}

@Test func photoCapturePolicyChoosesFallbackQualityOnlyAfterOversizedEncoding() {
    #expect(PhotoCapturePolicy.preferredJPEGQuality == 0.8)
    #expect(PhotoCapturePolicy.fallbackJPEGQuality == 0.6)
    #expect(PhotoCapturePolicy.jpegQuality(afterEncodingByteCount: ScanUploadPolicy.maxImageBytes) == 0.8)
    #expect(PhotoCapturePolicy.jpegQuality(afterEncodingByteCount: ScanUploadPolicy.maxImageBytes + 1) == 0.6)
}
