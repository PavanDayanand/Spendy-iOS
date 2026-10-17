import ImageIO
import SwiftUI
import UniformTypeIdentifiers

struct ReceiptActionPayload {
    var images: [UIImage]
    var text: String?
    var sourceData: Data
}

enum ReceiptActionAttachmentLoader {
    enum ImportError: LocalizedError {
        case unsupported, tooLarge, unreadable, multipleDocuments, tooManyPages
        var errorDescription: String? {
            switch self {
            case .unsupported: "Share a receipt image, PDF, or payment text to Spendy."
            case .tooLarge: "Share a receipt smaller than 20 MB."
            case .unreadable: "This receipt could not be opened. Try sharing a screenshot."
            case .multipleDocuments: "Share one receipt document at a time."
            case .tooManyPages: "Share a receipt of up to three pages, rather than a full bank statement."
            }
        }
    }

    static func load(_ providers: [NSItemProvider], attributedText: String? = nil) async throws -> ReceiptActionPayload {
        let documents = providers.filter { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.image.identifier)
                || provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
                || provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
                || (provider.hasItemConformingToTypeIdentifier(UTType.data.identifier)
                    && !provider.hasItemConformingToTypeIdentifier(UTType.text.identifier)
                    && !provider.hasItemConformingToTypeIdentifier(UTType.url.identifier))
        }
        guard documents.count <= 1 else { throw ImportError.multipleDocuments }
        if let document = documents.first {
            let data: Data
            let preferredType = document.registeredTypeIdentifiers.first { UTType($0)?.conforms(to: .image) == true }
                ?? document.registeredTypeIdentifiers.first { UTType($0)?.conforms(to: .pdf) == true }
            if let preferredType {
                do { data = try await representation(document, type: preferredType) }
                catch {
                    if UTType(preferredType)?.conforms(to: .image) == true, document.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        return try await imagePayload(document)
                    }
                    throw error
                }
            } else if document.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                data = try await withCheckedThrowingContinuation { continuation in
                    document.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { value, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let url = value as? URL {
                            do { continuation.resume(returning: try readFile(url)) }
                            catch { continuation.resume(throwing: error) }
                        }
                        else if let data = value as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            do { continuation.resume(returning: try readFile(url)) }
                            catch { continuation.resume(throwing: error) }
                        }
                        else if let text = value as? String, let url = URL(string: text) {
                            do { continuation.resume(returning: try readFile(url)) }
                            catch { continuation.resume(throwing: error) }
                        }
                        else { continuation.resume(throwing: ImportError.unreadable) }
                    }
                }
            } else {
                data = try await representation(document, type: UTType.data.identifier)
            }
            do { return try decode(data) }
            catch ImportError.unreadable where document.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                return try await imagePayload(document)
            }
        }
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            let type = provider.registeredTypeIdentifiers.first { UTType($0)?.conforms(to: .plainText) == true }
                ?? UTType.plainText.identifier
            let data: Data = try await withCheckedThrowingContinuation { continuation in
                provider.loadItem(forTypeIdentifier: type, options: nil) { value, error in
                    if let error { continuation.resume(throwing: error) }
                    else if let text = value as? String { continuation.resume(returning: Data(text.utf8)) }
                    else if let data = value as? Data { continuation.resume(returning: data) }
                    else if let url = value as? URL {
                        do { continuation.resume(returning: try readFile(url)) }
                        catch { continuation.resume(throwing: error) }
                    }
                    else { continuation.resume(throwing: ImportError.unreadable) }
                }
            }
            return try textPayload(data)
        }
        if let attributedText, !attributedText.isEmpty { return try textPayload(Data(attributedText.utf8)) }
        throw ImportError.unsupported
    }

    static func decode(_ data: Data) throws -> ReceiptActionPayload {
        guard !data.isEmpty else { throw ImportError.unreadable }
        guard data.count <= 20 * 1024 * 1024 else { throw ImportError.tooLarge }
        if !data.starts(with: Data("%PDF-".utf8)), let source = CGImageSourceCreateWithData(data as CFData, nil),
           let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2000
           ] as CFDictionary) {
            return ReceiptActionPayload(images: [UIImage(cgImage: image)], sourceData: data)
        }
        guard let provider = CGDataProvider(data: data as CFData), let document = CGPDFDocument(provider) else {
            throw ImportError.unreadable
        }
        guard !document.isEncrypted, document.numberOfPages > 0 else { throw ImportError.unreadable }
        guard document.numberOfPages <= 3 else { throw ImportError.tooManyPages }
        var images: [UIImage] = []
        for index in 1...document.numberOfPages {
            guard let page = document.page(at: index) else { throw ImportError.unreadable }
            let bounds = page.getBoxRect(.cropBox)
            guard bounds.width > 0, bounds.height > 0, bounds.width.isFinite, bounds.height.isFinite else { throw ImportError.unreadable }
            let factor = min(3, 2000 / max(bounds.width, bounds.height))
            let size = CGSize(width: bounds.width * factor, height: bounds.height * factor)
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            images.append(UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.white.setFill(); context.fill(CGRect(origin: .zero, size: size))
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                context.cgContext.concatenate(page.getDrawingTransform(.cropBox, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true))
                context.cgContext.drawPDFPage(page)
            })
        }
        return ReceiptActionPayload(images: images, sourceData: data)
    }

    private static func textPayload(_ data: Data) throws -> ReceiptActionPayload {
        guard data.count <= 50_000 else { throw ImportError.tooLarge }
        guard let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ImportError.unreadable }
        return ReceiptActionPayload(images: [], text: text, sourceData: data)
    }

    private static func imagePayload(_ provider: NSItemProvider) async throws -> ReceiptActionPayload {
        let image: UIImage = try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { value, error in
                if let error { continuation.resume(throwing: error) }
                else if let image = value as? UIImage { continuation.resume(returning: image) }
                else if let data = value as? Data, let image = UIImage(data: data) { continuation.resume(returning: image) }
                else if let url = value as? URL {
                    do {
                        let data = try readFile(url)
                        guard let image = UIImage(data: data) else { throw ImportError.unreadable }
                        continuation.resume(returning: image)
                    } catch { continuation.resume(throwing: error) }
                }
                else { continuation.resume(throwing: ImportError.unreadable) }
            }
        }
        guard image.size.width > 0, image.size.height > 0 else { throw ImportError.unreadable }
        let ratio = min(1, 2000 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let reduced = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = reduced.jpegData(compressionQuality: 0.95) else { throw ImportError.unreadable }
        return ReceiptActionPayload(images: [reduced], sourceData: data)
    }

    nonisolated private static func readFile(_ url: URL) throws -> Data {
        guard url.isFileURL else { throw ImportError.unsupported }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        var error: NSError?
        var result: Result<Data, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &error) { location in
            result = Result {
                let values = try location.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values.isRegularFile == true else { throw ImportError.unsupported }
                guard let size = values.fileSize, size <= 20 * 1024 * 1024 else { throw ImportError.tooLarge }
                return try Data(contentsOf: location, options: .mappedIfSafe)
            }
        }
        if let error { throw error }
        guard let result else { throw ImportError.unreadable }
        return try result.get()
    }

    private static func representation(_ provider: NSItemProvider, type: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type) { data, error in
                if let error { continuation.resume(throwing: error) }
                else if let data {
                    continuation.resume(returning: data)
                }
                else { continuation.resume(throwing: ImportError.unreadable) }
            }
        }
    }
}
