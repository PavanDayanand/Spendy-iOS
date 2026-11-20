import SwiftUI
import UIKit
import XCTest
@testable import Spendy

@MainActor final class MonthlyReceiptTests: XCTestCase {
    private let month = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 1))!

    private func transaction(_ amount: Double, type: TransactionType = .expense,
                             category: String = "coffee", date: Date? = nil) -> Spendy.Transaction {
        Spendy.Transaction(title: "Receipt fixture", amount: amount, type: type,
                    categoryId: category, accountId: "cash", date: date ?? month)
    }

    func testReportKeepsMonthYearAndCents() {
        let otherYear = Calendar.current.date(byAdding: .year, value: -1, to: month)!
        let otherMonth = Calendar.current.date(byAdding: .month, value: 1, to: month)!
        let report = MonthlyReceiptSnapshot(month: month, transactions: [
            transaction(19.95), transaction(0.05), transaction(100, type: .income),
            transaction(50, type: .transfer), transaction(900, date: otherYear), transaction(800, date: otherMonth)
        ], categories: [], currencySymbol: "₹")
        XCTAssertEqual(report.expenses, 20, accuracy: 0.0001)
        XCTAssertEqual(report.income, 100)
        XCTAssertEqual(report.transactionCount, 4)
        XCTAssertEqual(report.categories.count, 1)
        XCTAssertEqual(report.categories.first?.name, "Other")
        XCTAssertEqual(report.categories.first?.amount ?? 0, report.expenses, accuracy: 0.0001)
    }

    @MainActor func testStillPrintoutImmediatelyRendersCompletePaperAndDoesNotReplay() throws {
        let report = MonthlyReceiptSnapshot(month: month, transactions: [transaction(19.95)],
                                            categories: [], currencySymbol: "₹")
        func image(sequence: Int) throws -> UIImage {
            let renderer = ImageRenderer(content: MonthlyReceiptPrinter(snapshot: report, printSequence: sequence, animates: false)
                .frame(width: 360).fixedSize(horizontal: false, vertical: true))
            renderer.scale = 1
            return try XCTUnwrap(renderer.uiImage)
        }
        let first = try image(sequence: 0)
        let replay = try image(sequence: 1)
        XCTAssertGreaterThan(first.size.height, 400, "The complete receipt must be available immediately")
        XCTAssertEqual(first.pngData(), replay.pngData(), "The still presentation keeps replay visually unchanged")
    }

    @MainActor func testSharePaperIncludesLongBreakdown() throws {
        func image(categoryCount: Int) throws -> UIImage {
            let report = MonthlyReceiptSnapshot(month: month,
                transactions: (0..<categoryCount).map { transaction(1.25, category: "category-\($0)") },
                categories: [], currencySymbol: "₹")
            let renderer = ImageRenderer(content: MonthlyReceiptPaper(snapshot: report)
                .frame(width: 360).dynamicTypeSize(.medium))
            renderer.scale = 2
            return try XCTUnwrap(renderer.uiImage)
        }
        let short = try image(categoryCount: 1)
        let long = try image(categoryCount: 20)
        XCTAssertEqual(long.size.width, 360)
        XCTAssertGreaterThan(long.size.height, short.size.height + 200,
                             "Export must include every category rather than clipping to the sheet viewport")
    }
}
