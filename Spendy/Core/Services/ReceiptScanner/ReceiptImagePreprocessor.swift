import CoreImage
import ImageIO
import Vision

/// A bounded second OCR pass for photographed paper, not payment screenshots.
nonisolated enum ReceiptImagePreprocessor {
    static func rotatedImage(_ image: CGImage, orientation: CGImagePropertyOrientation,
                             quarterTurn: CGImagePropertyOrientation) -> CGImage? {
        let rotated = CIImage(cgImage: image).oriented(orientation).oriented(quarterTurn)
        return CIContext(options: [.cacheIntermediates: false]).createCGImage(rotated, from: rotated.extent)
    }

    static func documentImage(_ image: CGImage, orientation: CGImagePropertyOrientation) -> CGImage? {
        let source = CIImage(cgImage: image).oriented(orientation)
        let request = VNDetectRectanglesRequest()
        request.minimumConfidence = 0.8
        request.minimumAspectRatio = 0.12
        request.minimumSize = 0.12
        request.maximumObservations = 4
        request.quadratureTolerance = 35
        try? VNImageRequestHandler(ciImage: source).perform([request])

        let rectangle = request.results?.filter {
            let area = $0.boundingBox.width * $0.boundingBox.height
            return area >= 0.08 && area <= 0.92
        }.max { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }
        let context = CIContext(options: [.cacheIntermediates: false])
        var document = source
        if let rectangle {
            func point(_ point: CGPoint) -> CIVector {
                CIVector(x: source.extent.minX + point.x * source.extent.width,
                         y: source.extent.minY + point.y * source.extent.height)
            }
            document = source.applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": point(rectangle.topLeft), "inputTopRight": point(rectangle.topRight),
                "inputBottomLeft": point(rectangle.bottomLeft), "inputBottomRight": point(rectangle.bottomRight)
            ])
        }
        document = document.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0, kCIInputContrastKey: 1.15
        ]).applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.35])
        guard document.extent.width >= 100, document.extent.height >= 100 else { return nil }
        return context.createCGImage(document, from: document.extent)
    }
}
