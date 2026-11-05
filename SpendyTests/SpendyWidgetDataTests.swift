import XCTest
@testable import Spendy

final class SpendyWidgetDataTests: XCTestCase {
    private func manager(reload: @escaping @Sendable () -> Void = {}) -> WidgetDataManager {
        let suite = "widget-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return WidgetDataManager(defaults: defaults, containerURL: nil, reloadTimelines: reload)
    }

    func testEditedLedgerPersistsAndRequestsReload() {
        let reloaded = expectation(description: "Reload after each saved ledger")
        reloaded.expectedFulfillmentCount = 2
        let manager = manager { reloaded.fulfill() }
        let now = Date()
        manager.saveSnapshot(SpendyWidgetSnapshot(todayTotal: 100, monthTotal: 400, lastUpdated: now))
        manager.saveSnapshot(SpendyWidgetSnapshot(currencySymbol: "$", currencyCode: "USD", todayTotal: 75, monthTotal: 375, lastUpdated: now))
        let result = manager.loadSnapshot(asOf: now)
        XCTAssertEqual(result.todayTotal, 75)
        XCTAssertEqual(result.monthTotal, 375)
        XCTAssertEqual(result.currencyCode, "USD")
        wait(for: [reloaded], timeout: 1)
    }

    func testSiriExpenseRefreshesBudgetAndSelectedCategory() {
        let reloaded = expectation(description: "Initial ledger and Siri expense reload")
        reloaded.expectedFulfillmentCount = 2
        let manager = manager { reloaded.fulfill() }
        manager.saveSnapshot(SpendyWidgetSnapshot(todayTotal: 10, monthTotal: 10,
            remainingBudget: 90, budgetTotal: 100, budgetProgress: 0.1,
            categorySpending: [WidgetCategorySpend(id: "coffee", name: "Coffee", sfSymbol: "cup.and.saucer", colorHex: "#000000", amount: 10)], daysLeft: 10))
        manager.recordLoggedTransaction(amount: 25, isExpense: true, categoryId: "coffee", categoryName: "Coffee", categorySymbol: "cup.and.saucer", categoryColorHex: "#000000", note: nil)
        let result = manager.loadSnapshot()
        XCTAssertEqual(result.todayTotal, 35)
        XCTAssertEqual(result.remainingBudget, 65)
        XCTAssertEqual(result.budgetProgress, 0.35, accuracy: 0.001)
        XCTAssertEqual(result.categorySpending.first?.amount, 35)
        XCTAssertEqual(manager.loadPendingTransactions().count, 1)
        wait(for: [reloaded], timeout: 1)
    }

    func testMidnightClearsTodayAndPreservesDatedWeek() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let snapshot = SpendyWidgetSnapshot(todayTotal: 42, weeklySpending: [
            WidgetDaySpending(dayLabel: "X", amount: 42, isToday: true, dayStart: today)
        ], lastUpdated: today)
        let result = snapshot.normalized(for: tomorrow)
        XCTAssertEqual(result.todayTotal, 0)
        XCTAssertEqual(result.weeklySpending.count, 7)
        XCTAssertEqual(result.weeklySpending.reduce(0) { $0 + $1.amount }, 42)
        XCTAssertEqual(result.weeklySpending.last?.amount, 0)
        XCTAssertEqual(result.weeklySpending.last?.isToday, true)
    }

    func testNewMonthClearsCategoryAndMonthlyTotals() {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: Date())!.start
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: start)!
        let snapshot = SpendyWidgetSnapshot(monthTotal: 200, categorySpending: [
            WidgetCategorySpend(id: "coffee", name: "Coffee", sfSymbol: "cup.and.saucer", colorHex: "#000000", amount: 200)
        ], lastUpdated: start)
        let result = snapshot.normalized(for: nextMonth)
        XCTAssertEqual(result.monthTotal, 0)
        XCTAssertTrue(result.categorySpending.isEmpty)
        XCTAssertNil(result.previousMonthToDateTotal)
    }
}
