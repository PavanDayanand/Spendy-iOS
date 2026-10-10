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
                      calendar: Calendar = .current) -> [SpendyNotificationPlan] {
        var plans: [SpendyNotificationPlan] = []
        if bills {
            // Three quiet checkpoints per cycle; reserve room for weekly/logging reminders.
            for sub in subscriptions.filter({ !$0.isPaused && !$0.isCancelled }).sorted(by: { $0.nextBillingDate < $1.nextBillingDate }).prefix(16) {
                let amount = sub.amount.formatted(.currency(code: currencyCode))
                for offset in [-1, 0, 3] {
                    guard let day = calendar.date(byAdding: .day, value: offset, to: sub.nextBillingDate),
                          let date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day), date > now else { continue }
                    let title = offset < 0 ? "\(sub.name) is due tomorrow" : offset == 0 ? "\(sub.name) is due today" : "Still need to log \(sub.name)?"
                    let body = offset < 0 ? "\(amount) is due on \(sub.nextBillingDate.formatted(date: .abbreviated, time: .omitted))."
                        : offset == 0 ? "\(amount) is due today. If you've paid, record it in Spendy."
                        : "The \(amount) payment dated \(sub.nextBillingDate.formatted(date: .abbreviated, time: .omitted)) is still unrecorded. Log it if paid, or review the subscription."
                    plans.append(Self(id: "spendy.bill.\(sub.id).\(offset)", title: title, body: body,
                        date: date, url: "spendy://subscriptions"))
                }
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
