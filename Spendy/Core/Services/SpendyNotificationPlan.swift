import Foundation

struct SpendyNotificationPlan {
    let id: String
    let title: String
    let body: String
    let date: Date
    let url: String
    var repeatingWeekday: Int? = nil

    static func build(transactions: [Transaction], subscriptions: [Subscription], currencyCode: String,
                      bills: Bool, weekly: Bool, logging: Bool, now: Date = Date(),
                      calendar: Calendar = .current, budget: Budget? = nil, budgetStart: Date? = nil,
                      budgetEnd: Date? = nil, budgetAlerts: Bool = false) -> [SpendyNotificationPlan] {
        var plans: [SpendyNotificationPlan] = []
        if bills {
            // Three quiet checkpoints per cycle; reserve room for weekly/logging reminders.
            for sub in SubscriptionRenewalAttention.activeUnrecorded(subscriptions, transactions: transactions, now: now, calendar: calendar).sorted(by: { $0.nextBillingDate < $1.nextBillingDate }).prefix(16) {
                let amount = sub.amount.formatted(.currency(code: currencyCode))
                for offset in [-1, 0, 3] {
                    guard let day = calendar.date(byAdding: .day, value: offset, to: sub.nextBillingDate),
                          let scheduled = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) else { continue }
                    let catchUp = offset == 0 && calendar.isDate(day, inSameDayAs: now)
                        && (9..<21).contains(calendar.component(.hour, from: now))
                    let date = scheduled > now ? scheduled : catchUp ? now.addingTimeInterval(60) : scheduled
                    guard date > now else { continue }
                    let title = offset < 0 ? "\(sub.name) \(sub.isTrial ? "trial ends" : "is due") tomorrow" : offset == 0 ? "\(sub.name) \(sub.isTrial ? "trial ends" : "is due") today" : "Still need to log \(sub.name)?"
                    let body = offset < 0 ? "\(amount) is due on \(sub.nextBillingDate.formatted(date: .abbreviated, time: .omitted))."
                        : offset == 0 ? "\(amount) is due today. If you've paid, record it in Spendy."
                        : "The \(amount) payment dated \(sub.nextBillingDate.formatted(date: .abbreviated, time: .omitted)) is still unrecorded. Log it if paid, or review the subscription."
                    plans.append(Self(id: "spendy.bill.\(sub.id).\(Int(calendar.startOfDay(for: sub.nextBillingDate).timeIntervalSince1970)).\(offset)", title: title, body: body,
                        date: date, url: "spendy://subscriptions/\(sub.id.uuidString.lowercased())"))
                }
            }
        }

        if budgetAlerts, let budget, budget.isActive, budget.amount > 0,
           let start = budgetStart, let end = budgetEnd {
            let spent = transactions.filter { $0.type == .expense && $0.date >= start && $0.date < end && $0.date <= now }
                .reduce(0) { $0 + $1.amount }
            let ratio = spent / budget.amount
            if ratio >= 0.8 {
                let exceeded = ratio >= 1
                let value = (exceeded ? max(0, spent - budget.amount) : budget.amount - spent).formatted(.currency(code: currencyCode))
                let title = exceeded ? "Your budget limit is reached" : "Your budget is nearly used"
                let body = exceeded ? (spent > budget.amount ? "\(value) over the limit, based on recorded expenses. Open your budget to review." : "Recorded expenses have reached your budget limit. Open Spendy to review.")
                    : "\(value) remains in your current budget cycle. Open Spendy to review."
                plans.append(Self(id: "spendy.budget.\(Int(start.timeIntervalSince1970)).\(exceeded ? 100 : 80)",
                    title: title, body: body, date: now.addingTimeInterval(60), url: "spendy://budget"))
            }
        }

        if weekly {
            let nextSunday = calendar.nextDate(after: now, matching: DateComponents(hour: 20, minute: 0, weekday: 1),
                                               matchingPolicy: .nextTime) ?? now.addingTimeInterval(7 * 86400)
            for offset in 0..<8 {
                guard let date = calendar.date(byAdding: .weekOfYear, value: offset, to: nextSunday),
                      let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: date)) else { continue }
                var body = "Take a quiet look at your week's spending, categories, and patterns."
                if now >= start && now <= date {
                    let expenses = transactions.filter { $0.type == .expense && $0.date >= start && $0.date <= now }
                    if !expenses.isEmpty {
                        let amount = expenses.reduce(0) { $0 + $1.amount }.formatted(.currency(code: currencyCode))
                        body = "\(amount) logged for \(start.formatted(.dateTime.month(.abbreviated).day()))–\(date.formatted(.dateTime.month(.abbreviated).day())). Updated \(now.formatted(date: .abbreviated, time: .shortened)). Open for the latest totals."
                    }
                }
                plans.append(Self(id: "spendy.weekly.\(offset)", title: "Your week in Spendy", body: body,
                                  date: date, url: "spendy://weekly-summary/\(date.timeIntervalSince1970)"))
            }
        }
        if logging {
            for weekday in [3, 6] { // Tuesday and Friday, local time.
                if let date = calendar.nextDate(after: now, matching: DateComponents(hour: 20, minute: 0, weekday: weekday), matchingPolicy: .nextTime) {
                    plans.append(Self(id: "spendy.logging.\(weekday)", title: "A little spending check-in",
                        body: "Anything to log? A few seconds now can make your spending picture clearer.",
                        date: date, url: "spendy://quick-add", repeatingWeekday: weekday))
                }
            }
        }
        return plans
    }
}

enum AttentionNotificationPolicy {
    static func shouldSuppress(id: String, history: Set<String>, hasPending: Bool) -> Bool {
        if id.hasPrefix("spendy.budget."), id.hasSuffix(".80"),
           history.contains(String(id.dropLast(2)) + "100") { return true }
        return !hasPending && history.contains(id)
    }

    static func deliveryDate(proposed: Date, pending: Date?) -> Date { pending ?? proposed }
}
