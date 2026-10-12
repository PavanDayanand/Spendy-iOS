import XCTest
import UIKit
import FoundationModels
@testable import Spendy

final class ReceiptAmountParserTests: XCTestCase {
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
