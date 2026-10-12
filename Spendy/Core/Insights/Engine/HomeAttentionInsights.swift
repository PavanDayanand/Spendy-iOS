import Foundation

/// Current actionable facts are independent of Home's selected account or chart month.
enum HomeAttentionInsights {
    static func build(transactions: [Transaction] = [], subscriptions: [Subscription], budget: Budget, cycleSpent: Double,
                      currencySymbol: String, now: Date = Date(), calendar: Calendar = .current) -> [InsightMoment] {
        let active = SubscriptionRenewalAttention.activeUnrecorded(subscriptions, transactions: transactions, now: now, calendar: calendar)
        let today = active.filter { calendar.isDate($0.nextBillingDate, inSameDayAs: now) }
        var moments: [InsightMoment] = []
        func renewal(_ subs: [Subscription], days: Int) -> InsightMoment {
            let amount = subs.reduce(0) { $0 + $1.amount }.formattedCurrency(symbol: currencySymbol)
            let when = days == 0 ? "today" : days == 1 ? "tomorrow" : "in \(days) days"
            let headline = subs.count == 1
                ? "\(subs[0].name) \(subs[0].isTrial ? "trial ends" : "renews") \(when) · \(amount)"
                : "\(subs.count) renewals \(when) · \(amount)"
            return InsightMoment(id: "home_renewals_\(days)_\(subs.map { $0.id.uuidString }.sorted().joined())",
                candidateId: "home_renewals", kind: .observation, family: .subscription, surface: .home,
                headline: headline, supportingText: "Expected charges. Record payments once confirmed.",
                emphasis: [.highlight(when)], destination: subs.count == 1 ? .subscriptionDetail(id: subs[0].id.uuidString.lowercased()) : .subscriptions,
                attentionPriority: days == 0 ? 3 : 1, attentionLabel: days == 0 ? "Today" : "Upcoming")
        }
        if !today.isEmpty { moments.append(renewal(today, days: 0)) }
        let recentUnrecorded = active.filter {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.nextBillingDate), to: calendar.startOfDay(for: now)).day ?? 99
            return (1...7).contains(days)
        }
        if let first = recentUnrecorded.first {
            let headline = recentUnrecorded.count == 1 ? "\(first.name)’s renewal is unrecorded" : "\(recentUnrecorded.count) renewals need a payment check"
            moments.append(InsightMoment(id: "home_unrecorded_\(recentUnrecorded.map { $0.id.uuidString }.sorted().joined())",
                candidateId: "home_unrecorded", kind: .warning, family: .subscription, surface: .home,
                headline: headline, supportingText: "A renewal date has passed. Check whether it was paid before recording it.",
                destination: recentUnrecorded.count == 1 ? .subscriptionDetail(id: first.id.uuidString.lowercased()) : .subscriptions,
                attentionPriority: 2, attentionLabel: "Check payment"))
        }
        if budget.isActive && budget.amount > 0 && cycleSpent >= budget.amount * 0.8 {
            let exceeded = cycleSpent >= budget.amount
            let value = exceeded ? max(0, cycleSpent - budget.amount) : max(0, budget.amount - cycleSpent)
            let amount = value.formattedCurrency(symbol: currencySymbol)
            moments.append(InsightMoment(id: "home_budget_\(exceeded ? "exceeded" : "near")",
                candidateId: "home_budget", kind: .warning, family: .budget, surface: .home,
                headline: exceeded ? (value > 0 ? "\(amount) over your budget" : "Your budget limit is reached") : "\(amount) left in your budget",
                supportingText: "Based on recorded expenses in your current budget cycle.",
                emphasis: [.currency(value)], destination: .budget,
                attentionPriority: exceeded ? 2 : 1, attentionLabel: "Budget"))
        }
        if today.isEmpty,
           let next = active.filter({ $0.nextBillingDate > now }).min(by: { $0.nextBillingDate < $1.nextBillingDate }) {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: next.nextBillingDate)).day ?? 99
            if (1...3).contains(days) {
                moments.append(renewal(active.filter { calendar.isDate($0.nextBillingDate, inSameDayAs: next.nextBillingDate) }, days: days))
            }
        }
        return moments.sorted { $0.attentionPriority == $1.attentionPriority ? $0.id < $1.id : $0.attentionPriority > $1.attentionPriority }
    }
}

// A recorded payment is not an unpaid bill, even if imported renewal dates are stale.
enum SubscriptionRenewalAttention {
    static func activeUnrecorded(_ subscriptions: [Subscription], transactions: [Transaction], now: Date,
                                 calendar: Calendar = .current) -> [Subscription] {
        subscriptions.filter { sub in
            !sub.isPaused && !sub.isCancelled && !isRecorded(sub, transactions: transactions, now: now, calendar: calendar)
        }
    }

    static func isRecorded(_ sub: Subscription, transactions: [Transaction], now: Date, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: sub.nextBillingDate)
        return transactions.contains { tx in
            tx.type == .expense && tx.subscriptionId?.lowercased() == sub.id.uuidString.lowercased()
                && tx.date >= start && tx.date <= now
        }
    }
}
