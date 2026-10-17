import XCTest
import UIKit
@testable import Spendy

final class ReceiptFileImportTests: XCTestCase {
    private func temporaryFile(_ name: String = "receipt.png") throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appending(path: name)
    }

    @MainActor private func receiptData(width: CGFloat = 500, height: CGFloat = 700) throws -> Data {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return try XCTUnwrap(image.pngData())
    }

    @MainActor func testIncomingImageIsReadWithoutModifyingOriginal() throws {
        let url = try temporaryFile()
        let data = try receiptData()
        try data.write(to: url)
        let image = try ReceiptFileImport.image(at: url)
        XCTAssertEqual(image.size, CGSize(width: 500, height: 700))
        XCTAssertEqual(try Data(contentsOf: url), data)
    }

    @MainActor func testLargeImageIsDownsampledForReceiptReview() throws {
        let url = try temporaryFile()
        try receiptData(width: 3000, height: 4000).write(to: url)
        let image = try ReceiptFileImport.image(at: url)
        XCTAssertEqual(image.size.height, 2400)
        XCTAssertEqual(image.size.width, 1800)
    }

    @MainActor func testInvalidAndMissingFilesFailWithoutOpeningScanner() throws {
        let url = try temporaryFile()
        XCTAssertThrowsError(try ReceiptFileImport.image(at: url))
        try Data("not an image".utf8).write(to: url)
        XCTAssertThrowsError(try ReceiptFileImport.image(at: url))
        XCTAssertThrowsError(try ReceiptFileImport.image(at: url.deletingLastPathComponent()))
        XCTAssertThrowsError(try ReceiptFileImport.image(at: URL(string: "https://example.com/receipt.png")!))
    }

    @MainActor func testOversizedAttachmentIsRejectedBeforeDecoding() throws {
        let url = try temporaryFile()
        try Data(repeating: 0, count: 20 * 1024 * 1024 + 1).write(to: url)
        XCTAssertThrowsError(try ReceiptFileImport.image(at: url)) { error in
            XCTAssertEqual(error as? ReceiptFileImport.ImportError, .tooLarge)
        }
    }

    @MainActor func testFileURLRoutesToExistingReviewInsteadOfCameraOrAdd() throws {
        let manager = QuickActionManager.shared
        defer { manager.receivedReceiptImages = nil; manager.receiptFileImportError = nil }
        let url = try temporaryFile()
        try receiptData().write(to: url)
        manager.shouldPresentQuickAdd = false
        manager.shouldPresentReceiptScan = false
        manager.handleURL(url)
        XCTAssertEqual(manager.receivedReceiptImages?.count, 1)
        XCTAssertNil(manager.receiptFileImportError)
        XCTAssertFalse(manager.shouldPresentQuickAdd)
        XCTAssertFalse(manager.shouldPresentReceiptScan)
    }
}
