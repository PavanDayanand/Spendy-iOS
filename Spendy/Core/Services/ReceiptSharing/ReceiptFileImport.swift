import ImageIO
import UIKit

/// Read an incoming document while its security-scoped access is available.
enum ReceiptFileImport {
    enum ImportError: LocalizedError, Equatable {
        case unsupported, tooLarge, unreadable
        var errorDescription: String? {
            switch self {
            case .unsupported: "Open a receipt image in Spendy."
            case .tooLarge: "This image is too large. Share a smaller image or a screenshot."
            case .unreadable: "This receipt could not be opened. Try a screenshot instead."
            }
        }
    }
    static func image(at url: URL) throws -> UIImage {
        guard url.isFileURL else { throw ImportError.unsupported }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<UIImage, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { location in
            result = Result { try decodedImage(at: location) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw ImportError.unreadable }
        return try result.get()
    }

    private static func decodedImage(at url: URL) throws -> UIImage {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true else { throw ImportError.unsupported }
        guard let size = values.fileSize, size > 0, size <= 20 * 1024 * 1024 else {
            throw ImportError.tooLarge
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2400
              ] as CFDictionary) else { throw ImportError.unreadable }
        return UIImage(cgImage: image)
    }
}
