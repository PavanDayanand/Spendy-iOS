import XCTest
import UIKit
@testable import Spendy

final class ReceiptPhotoRegressionTests: XCTestCase {
    @MainActor func testUserReceiptPhotosWithoutAppleIntelligence() async throws {
        guard let directory = ProcessInfo.processInfo.environment["SPENDY_RECEIPT_FIXTURES_DIR"],
              !directory.isEmpty else {
            throw XCTSkip("Receipt photos are local only. Set SPENDY_RECEIPT_FIXTURES_DIR to an external fixture folder to run this check.")
        }
        let fixtureDirectory = URL(fileURLWithPath: directory, isDirectory: true)
        let fixtures: [(String, Double, String?, Int?, Int?)] = [
            ("restaurant-payable.jpeg", 8299, "restaurants", 26, 2),
            ("idli-grand-total.jpeg", 550, "restaurants", 21, 4),
            ("pista-house.jpg", 600, "restaurants", 9, 6),
            ("hospitality-dining.jpg", 12569, "restaurants", 26, 12),
            ("covered-header.jpg", 15809, "restaurants", nil, nil),
            ("us-ebt-deli.jpg", 26.48, "restaurants", 24, 7),
            ("sideways-rounded.jpg", 1470, "restaurants", nil, nil),
            ("obscured-tax-table.jpg", 0, nil, nil, nil),
            ("clothing-discount.jpg", 6755, "clothing", 1, 2)
        ]
        for (file, expected, category, day, month) in fixtures {
            let url = fixtureDirectory.appending(path: file)
            let image = try XCTUnwrap(UIImage(contentsOfFile: url.path), file)
            let result = await ReceiptScannerEngine.shared.scanImage(
                image, categories: Category.defaultExpenseCategories,
                accounts: [Account(id: "cash", label: "Cash", type: .cash), Account(id: "bank", label: "Bank")],
                defaultCurrencySymbol: "₹", allowsIntelligence: false
            )
            let report = "\(file): amount=\(result.totalAmount), note=\(result.merchantName), category=\(result.suggestedCategoryId ?? "none"), date=\(result.hasDetectedDate ? result.date.formatted(.iso8601) : "unknown")\n\(result.rawRecognizedText)"
            print("RECEIPT_PHOTO \(report)")
            let attachment = XCTAttachment(string: report)
            attachment.name = file
            attachment.lifetime = .keepAlways
            add(attachment)
            if expected == 0 {
                // The damaged tax-table image has no reliably legible final-total label.
                XCTAssertTrue(result.totalAmount == 0 || abs(result.totalAmount - 8896.9) < 0.01, file)
            } else {
                XCTAssertEqual(result.totalAmount, expected, accuracy: 0.01, file)
            }
            XCTAssertFalse(result.wasAssistedByAppleIntelligence, file)
            if let category { XCTAssertEqual(result.suggestedCategoryId, category, file) }
            if let day, let month {
                XCTAssertTrue(result.hasDetectedDate, file)
                XCTAssertEqual(Calendar.current.component(.day, from: result.date), day, file)
                XCTAssertEqual(Calendar.current.component(.month, from: result.date), month, file)
            }
            if file == "us-ebt-deli.jpg" { XCTAssertEqual(result.currencySymbol, "$", file) }
            if file == "clothing-discount.jpg" {
                XCTAssertTrue(result.merchantName.localizedCaseInsensitiveContains("Charms"), file)
                XCTAssertNotEqual(result.receiptType, .paymentScreenshot, file)
                XCTAssertEqual(result.suggestedAccountId, "bank", "Cash customer and cash amount zero do not identify the tender")
            }
            if file == "sideways-rounded.jpg" || file == "covered-header.jpg" {
                XCTAssertFalse(result.hasDetectedDate, file)
                XCTAssertEqual(result.merchantName, "Scanned Receipt", file)
            }
        }
    }

    func testFinalPayableAndRoundedTotalsBeatGrossAndTax() {
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Bill Total 7731.00", "Discount 402.50", "S Charge 731.95", "CGST 111.32", "Payable Amt 8299.00"]), 8299)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Gross Amount 12111.00", "Discount -5356.50", "Net Amount 6755.00", "Your savings -5356.50"]), 6755)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Bill Total 1470.06", "Bill Total (rounded)", "1,470.00"]), 1470)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["AMOUNT:", "$26.48", "FS Avail Bal:", "244.28"]), 26.48)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Grand Total 600. 00"]), 600)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["TOTAL:", "51120608"]), 0)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Latte 45.00"]), 0, "A single item does not establish the receipt total")
    }

    @MainActor func testAdditionalGeneratedReceiptLayoutsWithoutIntelligence() async {
        // These are synthetic layouts, separate from the nine supplied photographs.
        let fixtures: [([String], Double, String)] = [
            (["GREEN MARKET", "16/10/2026", "Item Qty Amount", "Basmati Rice 1 240.00", "Milk 2 120.00", "Sub Total 360.00", "Grand Total INR 360.00"], 360, "groceries"),
            (["CORNER CAFE", "10/16/2026", "Item Qty Amount", "Latte 2 10.00", "Cake 1 5.00", "Subtotal 15.00", "Tax 1.20", "Tip 3.00", "Total $19.20"], 19.2, "coffee"),
            (["SHELL", "16/10/2026", "Diesel 20.00 Litres", "Unit Price 92.50", "Amount INR 1850.00"], 1850, "fuel"),
            (["APOLLO PHARMACY", "16/10/2026", "Item Qty Amount", "Paracetamol 45.00", "Subtotal 45.00", "GST 2.25", "Net Amount INR 47.25"], 47.25, "health")
        ]
        for (lines, amount, category) in fixtures {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 1100, height: 1300)).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 1100, height: 1300))
                for (index, line) in lines.enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 35, y: 35 + index * 100), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 38), .foregroundColor: UIColor.black
                    ])
                }
            }
            let result = await ReceiptScannerEngine.shared.scanImage(image, categories: Category.defaultExpenseCategories,
                accounts: [], defaultCurrencySymbol: "₹", allowsIntelligence: false)
            XCTAssertEqual(result.totalAmount, amount, accuracy: 0.01, lines[0])
            XCTAssertEqual(result.suggestedCategoryId, category, lines[0])
            XCTAssertFalse(result.wasAssistedByAppleIntelligence, lines[0])
        }
    }

    func testSplitGrandTotalCanSortAfterItsValueOnSkewedPaper() {
        let lines: [ReceiptAmountParser.Line] = [
            .init(text: "600. 00", bounds: CGRect(x: 0.598, y: 0.536, width: 0.202, height: 0.044)),
            .init(text: "GRAND TOTAL", bounds: CGRect(x: 0.247, y: 0.512, width: 0.337, height: 0.043)),
            .init(text: "Total Tax", bounds: CGRect(x: 0.152, y: 0.365, width: 0.14, height: 0.032)),
            .init(text: "28.57", bounds: CGRect(x: 0.69, y: 0.404, width: 0.095, height: 0.031))
        ]
        XCTAssertEqual(ReceiptAmountParser.total(in: lines), 600)
    }

    func testDateOrderingUsesUnambiguousPrintedComponents() {
        let us = ReceiptFieldParser.date(in: [.init(text: "07/24/2020")], dayFirst: true)
        XCTAssertEqual(us.map { Calendar.current.component(.day, from: $0) }, 24)
        let india = ReceiptFieldParser.date(in: [.init(text: "21/04/26")], dayFirst: false)
        XCTAssertEqual(india.map { Calendar.current.component(.month, from: $0) }, 4)
        XCTAssertNil(ReceiptFieldParser.date(in: [.init(text: "31/02/2026")], dayFirst: true))
    }

    @MainActor func testCategorySuggestionsUseItemsAndSpecificExistingCategories() {
        let options = Category.defaultExpenseCategories.map { ReceiptCategoryMatcher.Option(id: $0.id, label: $0.label) }
        func match(_ name: String, _ text: String) -> String? {
            ReceiptCategoryMatcher.categoryID(merchant: name, receiptText: text, categories: options)
        }
        XCTAssertEqual(match("Unknown", "Ghee Podi Thatte Idli 75.00\nMasala Dosa 475.00"), "restaurants")
        XCTAssertEqual(match("M/S G.N HOSPITALITY", "Butter Naan\nChilly Paneer\nMineral Water"), "restaurants")
        XCTAssertEqual(match("CHARMS COLLECTIONS", "GENTS\nSweat 1399.00"), "clothing")
        XCTAssertEqual(match("All Season Market", "Biscuits\nNoodles"), "groceries")
        XCTAssertEqual(match("Swiggy", "Dosa\nIdli\nPaneer"), "food_delivery")
        XCTAssertEqual(match("Starbucks", "Latte"), "coffee")
        XCTAssertNil(match("Unknown", "Water 20.00\nTotal 20.00"))
        XCTAssertNil(match("Barcode Store", "Total 20.00"))
        XCTAssertNil(ReceiptCategoryMatcher.categoryID(merchant: "Unknown", receiptText: "Dosa", categories: [.init(id: "fuel", label: "Fuel")]))
        XCTAssertEqual(ReceiptCategoryMatcher.categoryID(merchant: "Unknown", receiptText: "Dosa", categories: [.init(id: "custom-food", label: "Food")]), "custom-food")
    }

    func testMissingReceiptHeaderDoesNotBecomeAnItemOrMetadata() {
        let partial = ["Bill Total", "Sub Total", "Jes", "Peri peri chicken burger", "1,470.00"].map { ReceiptAmountParser.Line(text: $0) }
        XCTAssertEqual(ReceiptFieldParser.merchant(in: partial, payment: false), "Merchant")
        let shop = ["TAX INVOICE", "CHARMS COLLECTIONS PVT. LTD.", "HEAD OFFICE", "Phone 0175-5007789", "Item Qty Amount"].map { ReceiptAmountParser.Line(text: $0) }
        XCTAssertEqual(ReceiptFieldParser.merchant(in: shop, payment: false), "Charms Collections Pvt. Ltd.")
    }
}
