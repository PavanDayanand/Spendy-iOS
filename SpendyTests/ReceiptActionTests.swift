import XCTest
import UIKit
import UniformTypeIdentifiers
@testable import Spendy

final class ReceiptActionTests: XCTestCase {
    @MainActor private func imageData() throws -> Data {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 900), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 600, height: 900))
        }
        return try XCTUnwrap(image.pngData())
    }

    private func provider(_ data: Data, type: UTType) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: type.identifier, visibility: .all) { complete in
            complete(data, nil); return nil
        }
        return provider
    }

    @MainActor func testMixedPlainTextAndImageUsesReceiptImage() async throws {
        let data = try imageData()
        let payload = try await ReceiptActionAttachmentLoader.load([
            NSItemProvider(object: "Sent using a payment app" as NSString), provider(data, type: .png)
        ])
        XCTAssertEqual(payload.images.count, 1)
        XCTAssertEqual(payload.images.first?.size.width, 600)
        XCTAssertNil(payload.text)
        XCTAssertEqual(payload.sourceData, data)
    }

    @MainActor func testImageObjectProviderAndRawDocumentData() async throws {
        let data = try imageData()
        let image = try XCTUnwrap(UIImage(data: data))
        let object = try await ReceiptActionAttachmentLoader.load([NSItemProvider(object: image)])
        XCTAssertEqual(object.images.count, 1)
        let generic = try await ReceiptActionAttachmentLoader.load([provider(data, type: .data)])
        XCTAssertEqual(generic.images.count, 1)
    }

    @MainActor func testTextOnlyPaymentAndAttributedContent() async throws {
        let text = "Google Pay\nPaid to Corner Cafe\n₹228\nCompleted\n17 Oct 2026"
        let payload = try await ReceiptActionAttachmentLoader.load([NSItemProvider(object: text as NSString)])
        XCTAssertEqual(payload.text, text)
        XCTAssertTrue(payload.images.isEmpty)
        let attributed = try await ReceiptActionAttachmentLoader.load([], attributedText: text)
        XCTAssertEqual(attributed.text, text)
    }

    @MainActor func testMixedTextAndPDFDocument() async throws {
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 600, height: 800)).pdfData { context in
            context.beginPage()
            ("Corner Cafe\nGrand Total INR 228" as NSString).draw(at: CGPoint(x: 30, y: 30), withAttributes: [.font: UIFont.systemFont(ofSize: 30)])
        }
        let payload = try await ReceiptActionAttachmentLoader.load([NSItemProvider(object: "Payment receipt" as NSString), provider(data, type: .pdf)])
        XCTAssertEqual(payload.images.count, 1)
        XCTAssertNil(payload.text)
        XCTAssertGreaterThan(payload.images[0].size.height, 800)
    }

    @MainActor func testLimitsRejectMultipleDocumentsAndLongPDFs() async throws {
        let data = try imageData()
        do {
            _ = try await ReceiptActionAttachmentLoader.load([provider(data, type: .png), provider(data, type: .png)])
            XCTFail("Multiple receipts should be reviewed separately")
        } catch { XCTAssertTrue(error is ReceiptActionAttachmentLoader.ImportError) }
        let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100)).pdfData { context in
            for _ in 0..<4 { context.beginPage() }
        }
        XCTAssertThrowsError(try ReceiptActionAttachmentLoader.decode(pdf))
        XCTAssertThrowsError(try ReceiptActionAttachmentLoader.decode(Data(repeating: 0, count: 20 * 1024 * 1024 + 1)))
        XCTAssertThrowsError(try ReceiptActionAttachmentLoader.decode(Data("not a receipt".utf8)))
    }

    @MainActor func testReviewedActionPersistsOnceAndRejectsUnsettledPayments() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let context = ReceiptShareContext(currencySymbol: "₹", currencyCode: "INR",
            categories: Category.defaultExpenseCategories, accounts: Account.defaultAccounts)
        try ReceiptShareStore.publish(context, at: root)
        var result = await ReceiptScannerEngine.shared.scanText("Google Pay\nPaid to Corner Cafe\n₹228\nCompleted\n17 Oct 2026\nUPI transaction ID 123456789012",
            categories: context.categories, accounts: context.accounts, defaultCurrencySymbol: "₹")
        result.suggestedCategoryId = "coffee"; result.suggestedAccountId = "cash"
        let source = Data("receipt".utf8)
        try ReceiptShareStore.enqueueReviewedReceipt(result, sourceData: source, context: context, at: root)
        XCTAssertEqual(try ReceiptShareStore.pending(at: root).count, 1)
        XCTAssertThrowsError(try ReceiptShareStore.enqueueReviewedReceipt(result, sourceData: source, context: context, at: root))
        result.paymentStatus = .pending
        XCTAssertThrowsError(try ReceiptShareStore.enqueueReviewedReceipt(result, sourceData: source, context: context, at: root))
        result.paymentStatus = .failed
        XCTAssertThrowsError(try ReceiptShareStore.enqueueReviewedReceipt(result, sourceData: source, context: context, at: root))
    }
}
