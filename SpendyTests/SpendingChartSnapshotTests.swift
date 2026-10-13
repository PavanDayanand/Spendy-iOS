import XCTest
@testable import Spendy

final class SpendingChartSnapshotTests: XCTestCase {
    func testSpendingScopeKeepsDatesAccountsAndCategorySelections() {
        let now = date(10, 11)
        let scope = SpendingScope(start: date(10, 1, hour: 0), end: date(11, 1, hour: 0), referenceDate: now,
            accountIDs: ["cash"], categoryIDs: ["food", "groceries"])
        XCTAssertTrue(scope.contains(expense(10, at: now)))
        XCTAssertTrue(scope.contains(expense(10, at: now, category: "groceries")))
        XCTAssertFalse(scope.contains(expense(10, at: now, account: "bank")))
        XCTAssertFalse(scope.contains(expense(10, at: now, category: "fuel")))
        XCTAssertFalse(scope.contains(expense(10, at: now.addingTimeInterval(1))))
        XCTAssertFalse(scope.contains(expense(10, at: date(9, 2))))
        XCTAssertTrue(scope.contains(expense(10, at: date(9, 2)), includeDates: false))
        let income = Transaction(title: "Income", amount: 50, type: .income, categoryId: "food", accountId: "cash", date: now)
        XCTAssertFalse(scope.contains(income))
        XCTAssertTrue(scope.contains(income, expensesOnly: false))
        let none = SpendingScope(start: scope.start, end: scope.end, referenceDate: now, categoryIDs: [])
        XCTAssertFalse(none.contains(expense(10, at: now)))
    }

    func testIncomeScopeAndSnapshotPreserveTypeAccountAndDates() {
        let now = date(10, 11)
        let income = Transaction(title: "Salary", amount: 500, type: .income, categoryId: "salary", accountId: "cash", date: now)
        let otherAccount = Transaction(title: "Other", amount: 900, type: .income, categoryId: "salary", accountId: "bank", date: now)
        let previous = Transaction(title: "Previous", amount: 300, type: .income, categoryId: "salary", accountId: "cash", date: date(9, 2))
        let snapshot = SpendingChartSnapshot(transactions: [income, otherAccount, previous, expense(20, at: now)],
            accountID: "cash", anchor: now, referenceDate: now, calendar: calendar, transactionType: .income)
        XCTAssertEqual(snapshot.total, 500)
        XCTAssertEqual(snapshot.baselineTotal, 300)
        XCTAssertEqual(snapshot.buckets.reduce(0) { $0 + $1.amount }, 500)
        let scope = SpendingScope(start: snapshot.start, end: snapshot.end, referenceDate: now,
            accountIDs: ["cash"], transactionType: .income)
        XCTAssertTrue(scope.contains(income))
        XCTAssertFalse(scope.contains(otherAccount))
        XCTAssertFalse(scope.contains(previous))
        XCTAssertFalse(scope.contains(expense(20, at: now), expensesOnly: false))
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private func date(_ month: Int, _ day: Int, hour: Int = 12, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
    private func expense(_ amount: Double, at date: Date, account: String = "cash", category: String = "food") -> Transaction {
        Transaction(title: "Recorded expense", amount: amount, categoryId: category, accountId: account, date: date)
    }

    func testAccountScopeAndRecordedTimeExcludeIncomeTransfersAndFuture() {
        let now = date(10, 11)
        let transactions = [
            expense(25, at: date(10, 1, hour: 0)), expense(5, at: now),
            expense(80, at: date(10, 2), account: "bank"), expense(999, at: now.addingTimeInterval(1)),
            expense(60, at: date(9, 30)),
            Transaction(title: "Income", amount: 500, type: .income, categoryId: "salary", accountId: "cash", date: now),
            Transaction(title: "Transfer", amount: 100, type: .transfer, categoryId: "transfer", accountId: "cash", toAccountId: "bank", date: now)
        ]
        let snapshot = SpendingChartSnapshot(transactions: transactions, accountID: "cash", anchor: now, referenceDate: now, calendar: calendar)
        XCTAssertEqual(snapshot.total, 30)
        XCTAssertEqual(snapshot.transactions.count, 2)
        XCTAssertEqual(snapshot.buckets.reduce(0) { $0 + $1.amount }, snapshot.total)
        XCTAssertEqual(snapshot.buckets.count, 2)
        XCTAssertEqual(snapshot.buckets.map(\.label), ["1–7", "8–14"])
        XCTAssertTrue(snapshot.buckets.last!.isInProgress)
    }

    func testMonthGroupsWeeklyTotalsAndClipsFinalRange() {
        let snapshot = SpendingChartSnapshot(transactions: [expense(20, at: date(9, 7)), expense(30, at: date(9, 8)), expense(40, at: date(9, 30))],
            anchor: date(9, 1), referenceDate: date(10, 12), calendar: calendar)
        XCTAssertEqual(snapshot.buckets.map(\.label), ["1–7", "8–14", "15–21", "22–28", "29–30"])
        XCTAssertEqual(snapshot.buckets.map(\.amount), [20, 30, 0, 0, 40])
        XCTAssertEqual(snapshot.buckets.reduce(0) { $0 + $1.transactionCount }, 3)
        XCTAssertEqual(snapshot.buckets.reduce(0) { $0 + $1.amount }, snapshot.total)
    }

    func testMonthBoundaryDoesNotCountMidnightTwice() {
        let boundary = date(10, 1, hour: 0)
        let transactions = [expense(40, at: boundary.addingTimeInterval(-0.01)), expense(70, at: boundary)]
        let old = SpendingChartSnapshot(transactions: transactions, anchor: date(9, 1), referenceDate: date(10, 11), calendar: calendar)
        let current = SpendingChartSnapshot(transactions: transactions, anchor: boundary, referenceDate: date(10, 11), calendar: calendar)
        XCTAssertEqual(old.total, 40)
        XCTAssertEqual(current.total, 70)
        XCTAssertEqual(old.buckets.last!.amount, 40)
    }

    func testComparisonUsesSameElapsedTimeIncludingFractionalSeconds() {
        let now = date(10, 11).addingTimeInterval(0.5)
        let previous = date(9, 11).addingTimeInterval(0.5)
        let transactions = [expense(60, at: date(10, 2)), expense(100, at: previous), expense(900, at: previous.addingTimeInterval(0.1))]
        let snapshot = SpendingChartSnapshot(transactions: transactions, anchor: now, referenceDate: now, calendar: calendar)
        XCTAssertEqual(snapshot.baselineCutoff, previous)
        XCTAssertEqual(snapshot.baselineTotal, 100)
        XCTAssertTrue(snapshot.comparisonText(currencySymbol: "₹").contains("less"))
    }

    func testShorterPreviousMonthClampsBeforeCurrentMonth() {
        let now = date(3, 31)
        let boundary = date(3, 1, hour: 0)
        let snapshot = SpendingChartSnapshot(transactions: [expense(15, at: boundary.addingTimeInterval(-0.01)), expense(100, at: boundary)],
            anchor: now, referenceDate: now, calendar: calendar)
        XCTAssertLessThan(snapshot.baselineCutoff, boundary)
        XCTAssertEqual(snapshot.baselineTotal, 15)
        XCTAssertEqual(snapshot.total, 100)
    }

    func testZeroBaselineAndEmptyHistoryDoNotInventPercentage() {
        let now = date(10, 11)
        let snapshot = SpendingChartSnapshot(transactions: [expense(20, at: now)], anchor: now, referenceDate: now, calendar: calendar)
        XCTAssertFalse(snapshot.hasBaselineRecords)
        XCTAssertFalse(snapshot.comparisonText(currencySymbol: "₹").contains("%"))
        let empty = SpendingChartSnapshot(transactions: [], anchor: now, referenceDate: now, calendar: calendar)
        XCTAssertNil(empty.leadingCategory)
        XCTAssertEqual(empty.total, 0)
    }

    func testSixMonthHistoryCrossesYearAndHasStableIDs() {
        let now = date(1, 15)
        let buckets = SpendingChartSnapshot.monthlyHistory(transactions: [expense(75, at: date(12, 2, year: 2025))], accountID: "all", referenceDate: now, calendar: calendar)
        XCTAssertEqual(buckets.count, 6)
        XCTAssertEqual(buckets.first!.start, date(8, 1, hour: 0, year: 2025))
        XCTAssertEqual(buckets[4].amount, 75)
        XCTAssertTrue(buckets.last!.isInProgress)
        XCTAssertEqual(Set(buckets.map(\.id)).count, 6)
    }

    func testCalendarBucketsHandleDaylightSavingAndRecordedZeroDays() {
        var local = calendar
        local.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let now = local.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!
        let snapshot = SpendingChartSnapshot(transactions: [], anchor: now, referenceDate: now, calendar: local)
        let secondWeek = snapshot.buckets[1]
        XCTAssertEqual(secondWeek.end.timeIntervalSince(secondWeek.start), (7 * 24 - 1) * 3600)
        XCTAssertEqual(snapshot.buckets.count, 2)
        XCTAssertTrue(snapshot.buckets.allSatisfy { $0.amount == 0 })
    }

    func testLeadingCategoryIsScopedAndDeterministic() {
        let now = date(10, 11)
        let transactions = [expense(50, at: now, category: "food"), expense(50, at: now, category: "coffee"), expense(500, at: now, account: "bank", category: "travel")]
        let snapshot = SpendingChartSnapshot(transactions: transactions, accountID: "cash", anchor: now, referenceDate: now, calendar: calendar)
        XCTAssertEqual(snapshot.leadingCategory?.id, "coffee")
        XCTAssertEqual(snapshot.leadingCategory?.share, 0.5)
    }

    func testHistoricalAndFuturePeriodsHaveExplicitSemantics() {
        let now = date(10, 11)
        let transactions = [expense(60, at: date(8, 31)), expense(40, at: date(9, 30))]
        let past = SpendingChartSnapshot(transactions: transactions, anchor: date(9, 1), referenceDate: now, calendar: calendar)
        XCTAssertFalse(past.isInProgress)
        XCTAssertEqual(past.baselineTotal, 60)
        XCTAssertEqual(past.buckets.count, 5)
        let future = SpendingChartSnapshot(transactions: transactions, anchor: date(11, 1), referenceDate: now, calendar: calendar)
        XCTAssertTrue(future.isFuture)
        XCTAssertTrue(future.buckets.isEmpty)
    }
}
