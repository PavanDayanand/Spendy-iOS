import XCTest
import UIKit
import FoundationModels
@testable import Spendy

final class ReceiptAmountParserTests: XCTestCase {
    @MainActor func testReceiptCurrencyAlwaysUsesSettingsWithoutChangingAmount() async {
        for selectedCurrency in ["₹", "€", "$"] {
            for receiptCurrency in ["₹", "€", "$"] {
                let result = await ReceiptScannerEngine.shared.scanText(
                    "Corner Cafe\n17 Oct 2026\nGrand Total \(receiptCurrency)135.50",
                    categories: [], accounts: [], defaultCurrencySymbol: selectedCurrency)
                XCTAssertEqual(result.currencySymbol, selectedCurrency)
                XCTAssertEqual(result.detectedCurrencySymbol, receiptCurrency)
                XCTAssertEqual(result.totalAmount, 135.50, accuracy: 0.001)
            }
        }
    }

    @MainActor func testVisionReceiptUsesSettingsWhenRupeeIsReadAsEuro() async {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 600)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 900, height: 600))
            for (index, line) in ["CORNER CAFE", "17 Oct 2026", "Grand Total €135.50"].enumerated() {
                (line as NSString).draw(at: CGPoint(x: 40, y: 40 + index * 95), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.black
                ])
            }
        }
        let result = await ReceiptScannerEngine.shared.scanImage(image, categories: [], accounts: [],
            defaultCurrencySymbol: "₹", allowsIntelligence: false)
        XCTAssertEqual(result.currencySymbol, "₹")
        XCTAssertEqual(result.detectedCurrencySymbol, "€")
        XCTAssertEqual(result.totalAmount, 135.50, accuracy: 0.001)
    }

    @MainActor func testReceiptWithoutCurrencyHasNoDetectedCurrencyHint() async {
        let result = await ReceiptScannerEngine.shared.scanText("Corner Cafe\nGrand Total 135.50",
            categories: [], accounts: [], defaultCurrencySymbol: "₹")
        XCTAssertNil(result.detectedCurrencySymbol)
        XCTAssertEqual(result.currencySymbol, "₹")
    }

    @MainActor func testVisionScanKeepsTotalInsteadOfAccountNumber() async {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 600)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 900, height: 600))
            for (index, line) in ["CORNER CAFE", "Account number: 123456", "Subtotal 900.00", "Tax 90.50", "Grand total 990.50", "Reference: 982345"].enumerated() {
                (line as NSString).draw(at: CGPoint(x: 40, y: 30 + index * 80), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.black
                ])
            }
        }
        let result = await ReceiptScannerEngine.shared.scanImage(image, categories: [], accounts: [], defaultCurrencySymbol: "₹")
        XCTAssertEqual(result.totalAmount, 990.5)
        XCTAssertFalse(result.rawRecognizedText.isEmpty)
        XCTAssertFalse(result.wasAssistedByAppleIntelligence)
    }

    @MainActor func testAvailableIntelligenceResolvesUnrecognizedTotalLabel() async throws {
        guard case .available = SystemLanguageModel.default.availability else {
            throw XCTSkip("This test requires an available on-device model.")
        }
        let lines = ["Coffee ₹40.00", "Charged to you ₹80.00", "Account 123456"]
        XCTAssertEqual(ReceiptAmountParser.total(in: lines), 0)
        var started = false
        let amount = await ReceiptIntelligenceFallback.amount(from: lines, onStarted: { started = true })
        XCTAssertTrue(started)
        XCTAssertEqual(amount, 80)
    }

    @MainActor func testUnavailableIntelligenceFallsBackToManualReview() async throws {
        guard case .unavailable = SystemLanguageModel.default.availability else {
            throw XCTSkip("This test requires a device without an available on-device model.")
        }
        var started = false
        let amount = await ReceiptIntelligenceFallback.amount(from: ["Coffee ₹40", "Cake ₹80"], onStarted: { started = true })
        XCTAssertFalse(started)
        XCTAssertNil(amount)
    }

    func testIntelligenceCanOnlySelectExistingSafeEvidence() {
        let candidates = ReceiptAmountParser.candidates(in: ["Coffee ₹40", "Paid at counter ₹80", "Account 123456"])
        XCTAssertEqual(candidates.map(\.amount), [40, 80])
        XCTAssertNil(ReceiptIntelligenceFallback.validatedAmount(candidateID: 0, candidates: candidates))
        XCTAssertNil(ReceiptIntelligenceFallback.validatedAmount(candidateID: -1, candidates: candidates))
        XCTAssertNil(ReceiptIntelligenceFallback.validatedAmount(candidateID: 3, candidates: candidates))
        XCTAssertEqual(ReceiptIntelligenceFallback.validatedAmount(candidateID: 2, candidates: candidates), 80)
    }

    func testRupeeRepairNeedsCorroborationAndKeepsRealLeadingSeven() {
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("=135", corroborating: "R135"), "₹135")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("=135", corroborating: nil), "=135")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("=135", corroborating: "R55"), "=135")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("71,250.50", corroborating: "R1,250.50"), "₹1,250.50")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("73,200", corroborating: "·3,200"), "₹3,200")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("71,250", corroborating: "71,250"), "71,250")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("71,250", corroborating: nil), "71,250")
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repair("71,250", corroborating: "R9,250"), "71,250")
    }

    func testProviderPaymentTextFixtures() {
        for fixture in Self.paymentFixtures {
            XCTAssertEqual(ReceiptAmountParser.total(in: fixture.lines), fixture.amount, fixture.provider)
        }
    }

    func testIndianGroupingAndHighValuePayments() {
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total INR 1,25,000.50"]), 125000.5)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Grand total ₹7,50,000"]), 750000)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total 3 items ₹990.00"]), 990)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total 990.00", "Grand total 1,000.00"]), 1000)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total ₹900", "Total ₹990"]), 0)
    }

    func testMetadataAndPromotionsCannotBecomePaymentTotals() {
        for lines in [["PhonePe", "UTR", "123456789012"], ["Paytm", "UPI ID", "1234.56"],
                      ["Google Pay", "Bank balance", "₹90000"], ["Paytm", "Cashback earned", "₹50"],
                      ["PhonePe", "Anjali12345@ybl"], ["Paytm", "HDFC Bank XX2345"]] {
            XCTAssertEqual(ReceiptAmountParser.total(in: lines), 0, "\(lines)")
        }
    }

    func testPaymentLayoutChoosesProminentAmountNotLargestNumber() {
        let lines: [ReceiptAmountParser.Line] = [
            .init(text: "Google Pay", bounds: CGRect(x: 0.1, y: 0.9, width: 0.5, height: 0.025)),
            .init(text: "₹500", bounds: CGRect(x: 0.1, y: 0.75, width: 0.5, height: 0.065)),
            .init(text: "₹900", bounds: CGRect(x: 0.1, y: 0.3, width: 0.5, height: 0.025))
        ]
        XCTAssertEqual(ReceiptAmountParser.total(in: lines), 500)
        XCTAssertEqual(ReceiptAmountParser.total(in: lines.map(\.text)), 0)
        XCTAssertEqual(ReceiptAmountParser.total(in: [lines[0], .init(text: "500", bounds: lines[1].bounds)]), 500)
    }

    func testUnsettledPaymentStatuses() {
        XCTAssertEqual(ReceiptPaymentStatus.detect(in: "PhonePe\nPayment Pending\n₹500"), .pending)
        XCTAssertEqual(ReceiptPaymentStatus.detect(in: "Paytm\nPayment Failed\n₹500"), .failed)
        XCTAssertEqual(ReceiptPaymentStatus.detect(in: "Google Pay\nFailed\n₹500"), .failed)
        XCTAssertEqual(ReceiptPaymentStatus.detect(in: "Google Pay\nTransaction Successful\n₹500"), .completed)
        XCTAssertEqual(ReceiptPaymentStatus.detect(in: "Corner Cafe\nTotal ₹500"), .unknown)
    }

    @MainActor func testProviderImagesThroughVisionInBothAppearances() async {
        // Synthetic fixtures model provider fields; these are not captured app screenshots.
        for dark in [false, true] {
            for fixture in Self.paymentFixtures {
                let image = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1500)).image { context in
                    (dark ? UIColor.black : UIColor.white).setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 900, height: 1500))
                    for (index, line) in fixture.lines.enumerated() {
                        let isAmount = ReceiptAmountParser.hasCurrency(line) && index < 4
                        (line as NSString).draw(at: CGPoint(x: 40, y: 40 + index * 90), withAttributes: [
                            .font: UIFont.systemFont(ofSize: isAmount ? 58 : 32),
                            .foregroundColor: dark ? UIColor.white : UIColor.black
                        ])
                    }
                }
                let result = await ReceiptScannerEngine.shared.scanImage(image, categories: [], accounts: [], defaultCurrencySymbol: "₹")
                XCTAssertEqual(result.totalAmount, fixture.amount, "\(fixture.provider), dark: \(dark), OCR: \(result.rawRecognizedText)")
                XCTAssertEqual(result.merchantName, fixture.merchant, fixture.provider)
                XCTAssertEqual(result.currencySymbol, "₹", fixture.provider)
                XCTAssertTrue(result.hasDetectedDate, fixture.provider)
                XCTAssertEqual(Calendar.current.component(.day, from: result.date), 12)
                XCTAssertFalse(result.wasAssistedByAppleIntelligence)
                XCTAssertEqual(result.transactionType, fixture.income ? .income : .expense)
            }
        }
    }

    @MainActor func testPaymentSourceAccountExcludesRecipientAndCashback() async {
        let accounts = [Account(id: "sbi", label: "SBI"), Account(id: "canara", label: "Canara"), Account(id: "cash", label: "Cash", type: .cash)]
        func image(_ lines: [String]) -> UIImage {
            UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1400)).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 900, height: 1400))
                for (index, line) in lines.enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 40, y: 30 + index * 90), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.black
                    ])
                }
            }
        }
        let fromBank = await ReceiptScannerEngine.shared.scanImage(image(["PhonePe", "Transaction Successful", "Rs. 750", "Paid to Canara", "12 Oct 2026", "Debited from", "SBI XX1234", "UPI Ref 123456789012", "Cashback earned Rs. 25"]), categories: [], accounts: accounts, defaultCurrencySymbol: "₹")
        XCTAssertEqual(fromBank.suggestedAccountId, "sbi")
        let unknownBank = await ReceiptScannerEngine.shared.scanImage(image(["Paytm", "Paid Successfully", "Rs. 750", "To Corner Cafe", "12 Oct 2026", "Cashback earned Rs. 25"]), categories: [], accounts: accounts, defaultCurrencySymbol: "₹")
        XCTAssertNil(unknownBank.suggestedAccountId)
    }

    @MainActor func testNumericReceiptDateUsesDetectedCurrencyConvention() async {
        for (symbol, expectedDay, expectedMonth) in [("₹", 10, 12), ("$", 12, 10)] {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 600)).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 900, height: 600))
                for (index, line) in ["CORNER CAFE", "10/12/2026", "Total 750.00"].enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 40, y: 40 + index * 95), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.black
                    ])
                }
            }
            let result = await ReceiptScannerEngine.shared.scanImage(image, categories: [], accounts: [], defaultCurrencySymbol: symbol)
            XCTAssertTrue(result.hasDetectedDate)
            XCTAssertEqual(Calendar.current.component(.day, from: result.date), expectedDay)
            XCTAssertEqual(Calendar.current.component(.month, from: result.date), expectedMonth)
        }
    }


    func testRealGooglePayGlyphAndRecipientRegressions() {
        for (raw, amount, recipient, date) in [
            ("₴55", 55.0, "All Season Market Counter 3", "12 October 2026, 7:13pm"),
            ("₴135", 135.0, "SRI GANESHA ENTERPRISES", "12 Oct 2026, 7:01pm")
        ] {
            let repaired = ReceiptOCRCurrencyRepair.repairIndianPaymentGlyph(raw)
            let lines = [repaired, "Paid to", recipient, date, "UPI"]
            XCTAssertEqual(ReceiptAmountParser.total(in: lines), amount)
            XCTAssertEqual(ReceiptFieldParser.merchant(in: lines.map { .init(text: $0) }, payment: true), recipient.capitalized)
            let detected = ReceiptFieldParser.date(in: lines.map { .init(text: $0) }, dayFirst: true)
            XCTAssertNotNil(detected)
            XCTAssertEqual(detected.map { Calendar.current.component(.month, from: $0) }, 10)
            XCTAssertEqual(detected.map { Calendar.current.component(.day, from: $0) }, 12)
        }
        XCTAssertEqual(ReceiptOCRCurrencyRepair.repairIndianPaymentGlyph("7135"), "7135")
    }

    func testReceiptMerchantIgnoresSurroundingHandwritingAndJoinsBrand() {
        let lines: [ReceiptAmountParser.Line] = [
            .init(text: "nont props. pr", bounds: CGRect(x: 0.03, y: 0.88, width: 0.18, height: 0.13)),
            .init(text: "ALL SEASON", bounds: CGRect(x: 0.33, y: 0.82, width: 0.28, height: 0.035)),
            .init(text: "MARKET", bounds: CGRect(x: 0.42, y: 0.80, width: 0.09, height: 0.017)),
            .init(text: "Ground & First Floor, Railway Layout", bounds: CGRect(x: 0.28, y: 0.78, width: 0.35, height: 0.023)),
            .init(text: "INVOICE", bounds: CGRect(x: 0.40, y: 0.71, width: 0.12, height: 0.023))
        ]
        XCTAssertEqual(ReceiptFieldParser.merchant(in: lines, payment: false), "All Season Market")
        let restaurant: [ReceiptAmountParser.Line] = [
            .init(text: "SVS BANGARPETE CHATS", bounds: CGRect(x: 0.31, y: 0.75, width: 0.31, height: 0.05)),
            .init(text: "Sri Ganesha Enterprises", bounds: CGRect(x: 0.31, y: 0.73, width: 0.33, height: 0.03)),
            .init(text: "Phone: 6364385445", bounds: CGRect(x: 0.34, y: 0.62, width: 0.25, height: 0.028)),
            .init(text: "Item", bounds: CGRect(x: 0.16, y: 0.44, width: 0.062, height: 0.02))
        ]
        XCTAssertEqual(ReceiptFieldParser.merchant(in: restaurant, payment: false), "Svs Bangarpete Chats")
        XCTAssertEqual(ReceiptFieldParser.merchant(in: [.init(text: "C"), .init(text: "SVS BANGARPETE CHATS"), .init(text: "Sri Ganesha Enterprises"), .init(text: "Item")], payment: false), "Svs Bangarpete Chats")
    }

    func testShortYearAndStrictReceiptDates() {
        for text in ["Date 12/10/26", "12-10-2026 19:01:37", "12.10.26", "2026-10-12"] {
            let date = ReceiptFieldParser.date(in: [.init(text: text)], dayFirst: true)
            XCTAssertNotNil(date, text)
            XCTAssertEqual(date.map { Calendar.current.component(.year, from: $0) }, 2026, text)
            XCTAssertEqual(date.map { Calendar.current.component(.month, from: $0) }, 10, text)
            XCTAssertEqual(date.map { Calendar.current.component(.day, from: $0) }, 12, text)
        }
        XCTAssertNil(ReceiptFieldParser.date(in: [.init(text: "31/02/26")], dayFirst: true))
    }

    func testSplitReceiptRowsExcludeQuantityAndUseGross() {
        let lines: [ReceiptAmountParser.Line] = [
            .init(text: "Total Qty 4.00", bounds: CGRect(x: 0.27, y: 0.50, width: 0.12, height: 0.016)),
            .init(text: "Gross", bounds: CGRect(x: 0.44, y: 0.465, width: 0.055, height: 0.015)),
            .init(text: "55.00", bounds: CGRect(x: 0.60, y: 0.465, width: 0.078, height: 0.020)),
            .init(text: "Total", bounds: CGRect(x: 0.29, y: 0.23, width: 0.04, height: 0.012)),
            .init(text: "52.38", bounds: CGRect(x: 0.38, y: 0.23, width: 0.04, height: 0.012))
        ]
        XCTAssertEqual(ReceiptAmountParser.total(in: lines), 55)
        XCTAssertFalse(ReceiptAmountParser.candidates(in: lines).contains { $0.amount == 4 })
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total Qty 4.00", "Gross 55.00"]), 55)
    }

    private struct PaymentFixture {
        let provider: String
        let lines: [String]
        let amount: Double
        let merchant: String
        var income = false
    }

    private static let paymentFixtures: [PaymentFixture] = [
        .init(provider: "PhonePe", lines: ["PhonePe", "Transaction Successful", "₹1,250.50", "Paid to", "Anjali Stores", "12 Oct 2026", "Debited from", "State Bank XX1234", "UPI transaction ID", "T2610121234567890123456", "UTR", "123456789012", "Get ₹50 cashback"], amount: 1250.5, merchant: "Anjali Stores"),
        .init(provider: "Paytm", lines: ["Paytm", "Paid Successfully", "Rs. 750", "To", "Corner Cafe", "12 Oct 2026", "UPI Ref No: 123456789012", "Paid by", "HDFC Bank XX2345", "Cashback earned", "₹25"], amount: 750, merchant: "Corner Cafe"),
        .init(provider: "Google Pay", lines: ["Google Pay", "Paid to Anjali", "₹2,499", "12 Oct 2026, 7:40 PM", "UPI transaction ID", "123456789012", "From", "State Bank XX9876", "Available balance", "₹90,000"], amount: 2499, merchant: "Anjali"),
        .init(provider: "Paytm incoming", lines: ["Paytm", "Money Received", "₹3,200", "Received from", "Anjali", "12 Oct 2026", "Credited to", "HDFC Bank XX1234", "UPI Ref 123456789012"], amount: 3200, merchant: "Anjali", income: true)
    ]

    func testIdentifiersCannotBecomeAmounts() {
        for lines in [["Account number", "123456"], ["A/C 123456", "UPI ref 982345"], ["Card **** 4567"], ["IFSC BANK0001234"], ["123456789012"], ["Reference: 1234.56"]] {
            XCTAssertEqual(ReceiptAmountParser.total(in: lines), 0, "\(lines)")
        }
    }
    func testActualTotalWinsOverAccountAndSubtotal() {
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Account 123456", "Subtotal 900.00", "Tax 90.00", "Grand total ₹990.00", "Card 4567"]), 990)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total", "375", "Reference", "982345"]), 375)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["₹", "375.00", "UPI ID 998877"]), 375)
    }
    func testAmbiguousAmountsRequireReview() {
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Coffee 40.00", "Cake 80.00"]), 0)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["₹40", "₹80"]), 0)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Subtotal 300.00", "Available balance ₹9000"]), 0)
    }
    func testGroupedAmountAndZeroTotal() {
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total INR 1,250.50"]), 1250.5)
        XCTAssertEqual(ReceiptAmountParser.total(in: ["Total 0.00"]), 0)
    }
}
