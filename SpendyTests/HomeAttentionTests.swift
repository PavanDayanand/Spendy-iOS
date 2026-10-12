import XCTest
@testable import Spendy

@MainActor
final class HomeAttentionTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    func testTodayRenewalsLeadAndAggregateWithoutPausedSubscriptions() {
        let subscriptions = [Subscription(name: "Music", amount: 99, nextBillingDate: date(12)),
                             Subscription(name: "Storage", amount: 49, nextBillingDate: date(12)),
                             Subscription(name: "Paused", amount: 1000, nextBillingDate: date(12), isPaused: true)]
        let moments = HomeAttentionInsights.build(subscriptions: subscriptions, budget: Budget(amount: 100, isActive: true),
            cycleSpent: 125, currencySymbol: "₹", now: date(12), calendar: calendar)
        XCTAssertEqual(moments.count, 2)
        XCTAssertEqual(moments[0].attentionLabel, "Today")
        XCTAssertTrue(moments[0].headline.contains("2 renewals"))
        XCTAssertTrue(moments[0].headline.contains("148"))
        XCTAssertEqual(moments[0].destination, .subscriptions)
        XCTAssertEqual(moments[1].destination, .budget)
    }

    func testTodayDoesNotHideOtherUpcomingDays() {
        let subs = (12...15).map { Subscription(name: "Day \($0)", amount: 99, nextBillingDate: date($0)) }
        let moments = HomeAttentionInsights.build(subscriptions: subs, budget: Budget(amount: 0, isActive: false),
            cycleSpent: 0, currencySymbol: "₹", now: date(12), calendar: calendar)
        XCTAssertEqual(moments.count, 4)
        XCTAssertEqual(moments.first?.attentionLabel, "Today")
        XCTAssertTrue(moments.contains { $0.headline.contains("tomorrow") })
        XCTAssertTrue(moments.contains { $0.headline.contains("in 2 days") })
        XCTAssertTrue(moments.contains { $0.headline.contains("in 3 days") })
    }

    func testHiddenInsightTextConcealsNumericClaims() {
        XCTAssertEqual(InsightMoment.concealedText("Music renews today · ₹1,299.50"), "Music renews today · ₹••••")
        XCTAssertEqual(InsightMoment.concealedText("Groceries · 62.9% of spending"), "Groceries · •••• of spending")
        XCTAssertEqual(InsightMoment.concealedText("Expected charges. Record payments once confirmed."), "Expected charges. Record payments once confirmed.")
    }

    func testSingleRenewalTargetsDetailAndRecordedPaymentSuppressesIt() {
        let sub = Subscription(name: "Music", amount: 12.99, nextBillingDate: date(12))
        func moments(_ transactions: [Transaction]) -> [InsightMoment] {
            HomeAttentionInsights.build(transactions: transactions, subscriptions: [sub], budget: Budget(amount: 0, isActive: false),
                cycleSpent: 0, currencySymbol: "₹", now: date(12), calendar: calendar)
        }
        XCTAssertEqual(moments([]).first?.destination, .subscriptionDetail(id: sub.id.uuidString.lowercased()))
        XCTAssertTrue(moments([]).first?.headline.contains("12.99") == true)
        let payment = Transaction(title: "Music", amount: 12.99, categoryId: "subscriptions", accountId: "cash", date: date(12, hour: 9), subscriptionId: sub.id.uuidString)
        XCTAssertTrue(moments([payment]).isEmpty)
    }

    func testPastRenewalIsUnrecordedRatherThanClaimedUnpaid() {
        let sub = Subscription(name: "Music", amount: 99, nextBillingDate: date(11))
        let moment = HomeAttentionInsights.build(subscriptions: [sub], budget: Budget(amount: 0, isActive: false), cycleSpent: 0,
            currencySymbol: "₹", now: date(12), calendar: calendar).first
        XCTAssertTrue(moment?.headline.contains("unrecorded") == true)
        XCTAssertEqual(moment?.attentionLabel, "Check payment")
    }

    func testBudgetNotificationsAreOptInAndIgnoreIncomeAndFutureExpenses() {
        let budget = Budget(amount: 100, isActive: true)
        let txs = [Transaction(title: "Expense", amount: 85, categoryId: "groceries", accountId: "cash", date: date(11)),
                   Transaction(title: "Income", amount: 500, type: .income, categoryId: "salary", accountId: "cash", date: date(11)),
                   Transaction(title: "Future", amount: 500, categoryId: "groceries", accountId: "cash", date: date(20))]
        func plans(_ enabled: Bool) -> [SpendyNotificationPlan] {
            SpendyNotificationPlan.build(transactions: txs, subscriptions: [], currencyCode: "INR", bills: false,
                weekly: false, logging: false, now: date(12), calendar: calendar,
                budget: budget, budgetStart: date(1, hour: 0), budgetEnd: date(31, hour: 0), budgetAlerts: enabled)
        }
        XCTAssertTrue(plans(false).isEmpty)
        XCTAssertEqual(plans(true).count, 1)
        XCTAssertTrue(plans(true)[0].id.hasSuffix(".80"))
        XCTAssertTrue(plans(true)[0].body.contains("15"))
        XCTAssertEqual(plans(true)[0].url, "spendy://budget")
    }

    func testDueTodayCatchupHasStableCycleIDAndExactDetailLink() {
        let sub = Subscription(name: "Music", amount: 99, nextBillingDate: date(12))
        func plans(_ now: Date) -> [SpendyNotificationPlan] {
            SpendyNotificationPlan.build(transactions: [], subscriptions: [sub], currencyCode: "INR", bills: true,
                weekly: false, logging: false, now: now, calendar: calendar)
        }
        let first = plans(date(12)).first { $0.title.contains("due today") }
        let next = plans(date(12, hour: 14)).first { $0.title.contains("due today") }
        XCTAssertEqual(first?.id, next?.id)
        XCTAssertEqual(first?.date, date(12).addingTimeInterval(60))
        XCTAssertEqual(first?.url, "spendy://subscriptions/\(sub.id.uuidString.lowercased())")
        let advanced = Subscription(id: sub.id, name: sub.name, amount: sub.amount, nextBillingDate: date(20))
        let future = SpendyNotificationPlan.build(transactions: [], subscriptions: [advanced], currencyCode: "INR", bills: true,
            weekly: false, logging: false, now: date(12), calendar: calendar)
        XCTAssertFalse(future.contains { $0.id == first?.id })
    }

    func testNotificationHistoryDoesNotReplayOrPostponeAttention() {
        let id = "spendy.budget.1790812800.80"
        XCTAssertTrue(AttentionNotificationPolicy.shouldSuppress(id: id, history: [id], hasPending: false))
        XCTAssertFalse(AttentionNotificationPolicy.shouldSuppress(id: id, history: [id], hasPending: true))
        XCTAssertTrue(AttentionNotificationPolicy.shouldSuppress(id: id, history: ["spendy.budget.1790812800.100"], hasPending: false))
        XCTAssertFalse(AttentionNotificationPolicy.shouldSuppress(id: "spendy.budget.1793491200.80", history: [id], hasPending: false))
        XCTAssertEqual(AttentionNotificationPolicy.deliveryDate(proposed: date(12, hour: 14), pending: date(12)), date(12))
    }

    func testSubscriptionURLUsesExistingHomeDetailRoute() {
        let manager = QuickActionManager.shared
        let id = UUID()
        manager.handleURL(URL(string: "spendy://subscriptions/\(id.uuidString)")!)
        XCTAssertEqual(manager.targetTab, .home)
        XCTAssertEqual(manager.requestedSubscriptionId, id.uuidString.lowercased())
        manager.targetTab = nil
        manager.requestedSubscriptionId = nil
    }
}
