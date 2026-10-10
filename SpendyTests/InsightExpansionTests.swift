import XCTest
@testable import Spendy

final class InsightExpansionTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private func date(_ day: Int, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    private let category = Category(id: "food", label: "Food", sfSymbol: "fork.knife", colorHex: "")
    private func facts(scope: AnalyticsInsightContext.Scope = .category(id: "food")) -> InsightFacts {
        let transactions = [2, 5, 8].enumerated().map {
            Transaction(title: "Expense \($0.offset)", amount: Double(($0.offset + 1) * 100),
                categoryId: "food", accountId: "cash", date: date($0.element))
        }
        return InsightFactsExtractor.extractFacts(transactions: transactions, budget: Budget(), categories: [category],
            subscriptions: [], context: .standard(period: .month, scope: scope, referenceDate: date(10), calendar: calendar), calendar: calendar)
    }

    @MainActor func testCategoryCanShowSeveralDistinctFactsFromOneFamily() {
        let output = InsightDecisionEngine().evaluate(facts: facts(), surface: .category(id: "food"))
        XCTAssertGreaterThanOrEqual(output.count, 4)
        XCTAssertLessThanOrEqual(output.count, 5)
        XCTAssertTrue(output.contains { $0.candidateId.hasPrefix("largest_expense") })
        XCTAssertTrue(output.contains { $0.candidateId.hasPrefix("average_expense") })
        XCTAssertTrue(output.contains { $0.candidateId.hasPrefix("active_spending_days") })
    }

    @MainActor func testCapAppliesEvenToCriticalCandidates() {
        let output = InsightDecisionEngine(rules: [ManyCriticalInsights()]).evaluate(facts: facts(), surface: .category(id: "food"))
        XCTAssertEqual(output.count, 5)
        XCTAssertEqual(Set(output.map(\.id)).count, 5)
    }

    @MainActor func testOutliersRespectDatesTypeAndScope() {
        var transactions = (1...5).map { Transaction(title: "Food", amount: 10, categoryId: "food", accountId: "cash", date: date($0)) }
        let invalid = [
            Transaction(title: "Old", amount: 999, categoryId: "food", accountId: "cash", date: date(5, month: 9)),
            Transaction(title: "Future", amount: 999, categoryId: "food", accountId: "cash", date: date(20)),
            Transaction(title: "Income", amount: 999, type: .income, categoryId: "food", accountId: "cash", date: date(5)),
            Transaction(title: "Other account", amount: 999, categoryId: "food", accountId: "bank", date: date(5))
        ]
        transactions += invalid
        let facts = InsightFactsExtractor.extractFacts(transactions: transactions, budget: Budget(), categories: [category],
            subscriptions: [], context: .standard(period: .month, scope: .account(id: "cash"), referenceDate: date(10), calendar: calendar), calendar: calendar)
        let output = CategoryAnomalyRule().evaluate(facts: facts, context: InsightEvaluationContext(surface: .analytics, period: .month, currencySymbol: "₹", now: date(10)))
        XCTAssertTrue(output.isEmpty)
        let details = SpendingDetailRule().evaluate(facts: facts, context: InsightEvaluationContext(surface: .analytics, period: .month, currencySymbol: "₹", now: date(10)))
        XCTAssertFalse(details.contains { candidate in
            if case .largestExpense(let id, _, _, _) = candidate.evidence { return invalid.contains { $0.id == id } }
            return false
        })
    }

    @MainActor func testBudgetAllowanceIncludesTodayAndExactExhaustionDay() {
        let txs = [Transaction(title: "Food", amount: 500, categoryId: "food", accountId: "cash", date: date(5))]
        let facts = InsightFactsExtractor.extractFacts(transactions: txs,
            budget: Budget(amount: 1000, isActive: true), categories: [category], subscriptions: [],
            context: .standard(period: .month, referenceDate: date(10), calendar: calendar), calendar: calendar)
        XCTAssertEqual(facts.elapsedDays, 10)
        XCTAssertEqual(facts.remainingDays, 22)
        XCTAssertEqual(facts.budgetSafeDailyRemaining, 500 / 22, accuracy: 0.01)
        XCTAssertEqual(calendar.component(.day, from: facts.budgetExhaustionDate!), 20)
    }

    @MainActor func testHistoricalPeriodsDoNotMakeFuturePaceClaims() {
        let context = AnalyticsInsightContext.standard(period: .month, referenceDate: date(10), calendar: calendar)
        let historical = AnalyticsInsightContext(period: .month, startDate: context.baselineStartDate, endDate: context.baselineEndDate,
            baselineStartDate: date(1, month: 8), baselineEndDate: date(31, month: 8), referenceDate: date(10))
        let transactions = [5, 8].map { Transaction(title: "Food", amount: 100, categoryId: "food", accountId: "cash", date: date($0, month: 9)) }
            + [Transaction(title: "Old", amount: 50, categoryId: "food", accountId: "cash", date: date(5, month: 8))]
        let facts = InsightFactsExtractor.extractFacts(transactions: transactions, budget: Budget(), categories: [category], subscriptions: [], context: historical, calendar: calendar)
        XCTAssertTrue(SpendingVelocityRule().evaluate(facts: facts,
            context: InsightEvaluationContext(surface: .analytics, period: .month, currencySymbol: "₹", now: date(10))).isEmpty)
    }
    @MainActor func testWeeklySubscriptionRenewalsAreNotDuplicateBilling() {
        let sub = Subscription(name: "Music", amount: 10, cycle: .weekly, nextBillingDate: date(20))
        let txs = [2, 9].map { Transaction(title: "Renewal", amount: 10, categoryId: "food", accountId: "cash", date: date($0), subscriptionId: sub.id.uuidString) }
        let facts = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(), categories: [category], subscriptions: [sub],
            context: .standard(period: .month, referenceDate: date(10), calendar: calendar), calendar: calendar)
        XCTAssertEqual(facts.subscriptionExpensesInPeriod.count, 2)
        XCTAssertFalse(SubscriptionRule().evaluate(facts: facts,
            context: InsightEvaluationContext(surface: .subscriptions, period: .month, currencySymbol: "₹", now: date(10)))
            .contains { $0.semanticKey == "sub_double_billing" })
    }

    @MainActor func testComparableCutoffRetainsFractionalSeconds() {
        let now = date(10).addingTimeInterval(0.75)
        let context = AnalyticsInsightContext.standard(period: .month, referenceDate: now, calendar: calendar)
        XCTAssertEqual(InsightComparison.baselineEnd(context: context, calendar: calendar), date(10, month: 9).addingTimeInterval(0.75))
    }

}

private struct ManyCriticalInsights: InsightRule {
    let id = "cap_fixture"
    let family = InsightFamily.category
    let supportedPeriods: Set<InsightPeriod> = [.month]
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        (0..<9).map { index in
            InsightCandidate(id: "critical_\(index)", semanticKey: "critical_\(index)", family: .spending,
                kind: .warning, surfaceAffinity: [.category(id: "food")], period: .month,
                confidence: 1, severity: 1, relevance: 1, actionability: 0, materiality: 1,
                evidence: .recordedSpending(total: Double(index), count: 3, period: .month), isCritical: true)
        }
    }
}
