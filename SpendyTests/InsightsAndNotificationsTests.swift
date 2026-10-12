import XCTest
@testable import Spendy

final class InsightsAndNotificationsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }
    private func date(_ day: Int, month: Int = 10, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    @MainActor func testPartialMonthDoesNotCelebrateAgainstFullPreviousMonth() {
        let now = date(10)
        let category = Category(id: "food", label: "Food", sfSymbol: "fork.knife", colorHex: "")
        let txs = [
            Transaction(title: "Food", amount: 100, categoryId: "food", accountId: "cash", date: date(5)),
            Transaction(title: "Food", amount: 100, categoryId: "food", accountId: "cash", date: date(7)),
            Transaction(title: "Food", amount: 100, categoryId: "food", accountId: "cash", date: date(9)),
            Transaction(title: "Food", amount: 300, categoryId: "food", accountId: "cash", date: date(5, month: 9)),
            Transaction(title: "Food", amount: 1000, categoryId: "food", accountId: "cash", date: date(20, month: 9))
        ]
        let context = AnalyticsInsightContext.standard(period: .month, referenceDate: now, calendar: calendar)
        let facts = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, isActive: false),
            categories: [category], subscriptions: [], context: context, calendar: calendar)
        let comparisonEnd = InsightComparison.baselineEnd(context: context, calendar: calendar)
        XCTAssertEqual(comparisonEnd, date(10, month: 9))
        let candidates = CategoryTrendRule().evaluate(facts: facts,
            context: InsightEvaluationContext(surface: .analytics, period: .month, currencySymbol: "₹", now: now))
        XCTAssertFalse(candidates.contains { $0.semanticKey == "cat_savings" })
    }

    @MainActor func testFutureTransactionsAreNotReportedAsAlreadySpent() {
        let now = date(10)
        let facts = InsightFactsExtractor.extractFacts(transactions: [
            Transaction(title: "Today", amount: 20, categoryId: "food", accountId: "cash", date: date(9)),
            Transaction(title: "Future", amount: 900, categoryId: "food", accountId: "cash", date: date(20))
        ], budget: Budget(amount: 0, isActive: false), categories: [], subscriptions: [],
            context: .standard(period: .month, referenceDate: now, calendar: calendar), calendar: calendar)
        XCTAssertEqual(facts.currentSpendTotal, 20)
        XCTAssertEqual(facts.totalExpenseTxCount, 1)
    }

    @MainActor func testWeeklySnapshotExcludesTransfersAndFutureExpenses() {
        let plans = SpendyNotificationPlan.build(transactions: [
            Transaction(title: "Food", amount: 100, categoryId: "food", accountId: "cash", date: date(9)),
            Transaction(title: "Move", amount: 500, type: .transfer, categoryId: "", accountId: "cash", date: date(9)),
            Transaction(title: "Future", amount: 900, categoryId: "food", accountId: "cash", date: date(11))
        ], subscriptions: [], currencyCode: "INR", bills: false, weekly: true, logging: false,
            now: date(10), calendar: calendar)
        XCTAssertEqual(plans.count, 8)
        XCTAssertEqual(plans[0].date, date(11, hour: 20))
        XCTAssertTrue(plans[0].body.contains("100"))
        XCTAssertTrue(plans[0].body.contains("Updated"))
        XCTAssertFalse(plans[0].body.contains("900"))
        XCTAssertFalse(plans[1].body.contains("100"))
        XCTAssertTrue(plans[0].url.contains("weekly-summary"))
    }

    @MainActor func testNotificationPreferencesAndSubscriptionCurrency() {
        let active = Subscription(name: "Music", amount: 12, nextBillingDate: date(12))
        let paused = Subscription(name: "Paused", amount: 12, nextBillingDate: date(12), isPaused: true)
        XCTAssertTrue(SpendyNotificationPlan.build(transactions: [], subscriptions: [active], currencyCode: "INR",
            bills: false, weekly: false, logging: false, now: date(10), calendar: calendar).isEmpty)
        let plans = SpendyNotificationPlan.build(transactions: [], subscriptions: [active, paused], currencyCode: "EUR",
            bills: true, weekly: false, logging: true, now: date(10), calendar: calendar)
        XCTAssertEqual(plans.filter { $0.id.hasPrefix("spendy.bill") }.count, 3)
        XCTAssertTrue(plans[0].body.contains("€"))
        XCTAssertEqual(plans.filter { $0.repeatingWeekday != nil }.count, 2)
    }

    @MainActor func testPreferencesSurviveRelaunchAndExport() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("store.json")
        let store = ExpenseStore(storageURL: url, startsServices: false)
        store.insightsEnabled = false
        store.weeklySummaryEnabled = true
        store.loggingRemindersEnabled = true
        store.budgetAlertsEnabled = true
        store.flushPendingSave()
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertFalse(reloaded.insightsEnabled)
        XCTAssertTrue(reloaded.weeklySummaryEnabled)
        XCTAssertTrue(reloaded.loggingRemindersEnabled)
        XCTAssertTrue(reloaded.budgetAlertsEnabled)
        let imported = ExpenseStore(storageURL: folder.appendingPathComponent("import.json"), startsServices: false)
        XCTAssertTrue(imported.importJSONData(data: try XCTUnwrap(store.exportJSONData())))
        XCTAssertFalse(imported.insightsEnabled)
        XCTAssertTrue(imported.weeklySummaryEnabled)
        XCTAssertTrue(imported.budgetAlertsEnabled)
    }
    @MainActor func testWeeklyBudgetUsesConfiguredCycleAndIgnoresOtherRanges() {
        let now = date(10)
        let context = AnalyticsInsightContext(period: .week, startDate: date(5, hour: 0),
            endDate: date(12, hour: 0).addingTimeInterval(-1), baselineStartDate: date(28, month: 9, hour: 0),
            baselineEndDate: date(5, hour: 0).addingTimeInterval(-1), referenceDate: now)
        let txs = [Transaction(title: "Food", amount: 150, categoryId: "food", accountId: "cash", date: date(9))]
        let budget = Budget(amount: 100, period: .weekly, startDay: 2, isActive: true)
        let facts = InsightFactsExtractor.extractFacts(transactions: txs, budget: budget,
            categories: [], subscriptions: [], context: context, calendar: calendar)
        XCTAssertTrue(facts.hasActiveBudget)
        XCTAssertTrue(BudgetPacingRule().evaluate(facts: facts,
            context: InsightEvaluationContext(surface: .budget, period: .week, currencySymbol: "₹", now: now))
            .contains { $0.semanticKey == "budget_exceeded" })
        let otherRange = InsightFactsExtractor.extractFacts(transactions: txs, budget: budget,
            categories: [], subscriptions: [], context: .standard(period: .month, referenceDate: now, calendar: calendar), calendar: calendar)
        XCTAssertFalse(otherRange.hasActiveBudget)
    }

    @MainActor func testSubscriptionCheckpointsStopWhenPausedOrCycleAdvances() {
        var subscription = Subscription(name: "Music", amount: 12, nextBillingDate: date(12))
        func plans(_ sub: Subscription, now: Date) -> [SpendyNotificationPlan] {
            SpendyNotificationPlan.build(transactions: [], subscriptions: [sub], currencyCode: "INR",
                bills: true, weekly: false, logging: false, now: now, calendar: calendar)
        }
        XCTAssertEqual(plans(subscription, now: date(10)).map(\.date), [date(11, hour: 9), date(12, hour: 9), date(15, hour: 9)])
        let overdue = plans(subscription, now: date(13))
        XCTAssertEqual(overdue.count, 1)
        XCTAssertTrue(overdue[0].body.contains("unrecorded"))
        XCTAssertTrue(plans(subscription, now: date(16)).isEmpty)
        subscription.isPaused = true
        XCTAssertTrue(plans(subscription, now: date(10)).isEmpty)
        subscription.isPaused = false
        subscription.nextBillingDate = date(12, month: 11)
        XCTAssertFalse(plans(subscription, now: date(13)).contains { $0.body.contains("unrecorded") && $0.date == date(15, hour: 9) })
    }

}
