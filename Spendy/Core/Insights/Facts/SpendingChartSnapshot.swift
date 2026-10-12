import Foundation

/// Immutable expense context carried between charts, entity details and transaction browsing.
/// End is exclusive; nil entity selections mean all and an empty set means none.
struct SpendingScope {
    let start: Date
    let end: Date
    let referenceDate: Date
    var accountIDs: Set<String>? = nil
    var categoryIDs: Set<String>? = nil

    func contains(_ transaction: Transaction, includeDates: Bool = true, expensesOnly: Bool = true) -> Bool {
        (!expensesOnly || transaction.type == .expense) && transaction.amount.isFinite && transaction.amount >= 0
            && transaction.date <= referenceDate
            && (!includeDates || (transaction.date >= start && transaction.date < end))
            && (accountIDs?.contains(transaction.accountId) ?? true)
            && (categoryIDs?.contains(transaction.categoryId) ?? true)
    }
}


/// All dates are calendar boundaries; bucket ends are exclusive.
struct SpendingChartBucket: Identifiable, Equatable {
    let start: Date
    let end: Date
    let amount: Double
    let transactionCount: Int
    let label: String
    let isInProgress: Bool
    var id: String { String(start.timeIntervalSinceReferenceDate) }
}

enum SpendingChartPeriod: String {
    case day, week, month, year

    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    var insightPeriod: InsightPeriod {
        switch self {
        case .day: .custom
        case .week: .week
        case .month: .month
        case .year: .year
        }
    }
}

struct SpendingChartSnapshot {
    let period: SpendingChartPeriod
    let start: Date
    let end: Date
    let referenceDate: Date
    let baselineStart: Date
    let baselineEnd: Date
    let baselineCutoff: Date
    let transactions: [Transaction]
    let buckets: [SpendingChartBucket]
    let baselineTotal: Double
    let hasBaselineRecords: Bool

    var total: Double { transactions.reduce(0) { $0 + $1.amount } }
    var isInProgress: Bool { start <= referenceDate && referenceDate < end }
    var isFuture: Bool { start > referenceDate }
    var recordedEnd: Date { max(start, min(referenceDate, Date(timeIntervalSinceReferenceDate: end.timeIntervalSinceReferenceDate.nextDown))) }

    var leadingCategory: (id: String, amount: Double, share: Double)? {
        guard total > 0 else { return nil }
        var totals: [String: Double] = [:]
        for transaction in transactions { totals[transaction.categoryId, default: 0] += transaction.amount }
        let ordered = totals.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }
        guard let first = ordered.first else { return nil }
        return (first.key, first.value, first.value / total)
    }

    func comparisonText(currencySymbol: String) -> String {
        guard !isFuture else { return "This period hasn’t started yet" }
        guard hasBaselineRecords else { return "No spending recorded in the comparison period" }
        let difference = total - baselineTotal
        let comparison = isInProgress ? "the same period last \(period.rawValue)" : "the previous \(period.rawValue)"
        if abs(difference) < 0.005 { return "Same recorded spending as \(comparison)" }
        return "\(abs(difference).formattedCurrency(symbol: currencySymbol, decimals: 2)) \(difference < 0 ? "less" : "more") than \(comparison)"
    }

    init(transactions allTransactions: [Transaction], accountID: String = "all",
         period: SpendingChartPeriod = .month, anchor: Date, referenceDate: Date,
         calendar inputCalendar: Calendar = .current) {
        var calendar = inputCalendar
        calendar.firstWeekday = 2
        self.period = period
        self.referenceDate = referenceDate
        let interval = calendar.dateInterval(of: period.component, for: anchor)!
        start = interval.start
        end = interval.end
        let previousStart = calendar.date(byAdding: period.component, value: -1, to: interval.start)!
        baselineStart = previousStart
        baselineEnd = interval.start
        let context = AnalyticsInsightContext(
            scope: accountID == "all" ? .global : .account(id: accountID),
            period: period.insightPeriod, startDate: interval.start,
            endDate: Date(timeIntervalSinceReferenceDate: interval.end.timeIntervalSinceReferenceDate.nextDown),
            baselineStartDate: previousStart,
            baselineEndDate: Date(timeIntervalSinceReferenceDate: interval.start.timeIntervalSinceReferenceDate.nextDown),
            referenceDate: referenceDate
        )
        let previousCutoff = InsightComparison.baselineEnd(context: context, calendar: calendar)
        baselineCutoff = previousCutoff
        let expenses = allTransactions.filter {
            $0.type == .expense && $0.amount.isFinite && $0.amount >= 0 && $0.date <= referenceDate
                && (accountID == "all" || $0.accountId == accountID)
        }
        let recorded = expenses.filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date > $1.date }
        transactions = recorded
        let previous = expenses.filter { $0.date >= previousStart && $0.date < interval.start && $0.date <= previousCutoff }
        baselineTotal = previous.reduce(0) { $0 + $1.amount }
        hasBaselineRecords = !previous.isEmpty
        let unit: Calendar.Component = period == .year ? .month : period == .day ? .hour : .day
        let stride = period == .day ? 6 : period == .month ? 7 : 1
        let format = DateFormatter()
        format.calendar = calendar
        format.timeZone = calendar.timeZone
        format.setLocalizedDateFormatFromTemplate(period == .year ? "MMM" : period == .week ? "EEE" : period == .day ? "ha" : "d")
        var result: [SpendingChartBucket] = []
        var date = interval.start
        while date < interval.end && date <= referenceDate {
            guard let next = calendar.date(byAdding: unit, value: stride, to: date), next > date else { break }
            let bucketEnd = min(next, interval.end)
            let records = recorded.filter { $0.date >= date && $0.date < bucketEnd }
            let label: String
            if period == .month {
                let lastDay = calendar.date(byAdding: .day, value: -1, to: bucketEnd) ?? date
                label = "\(calendar.component(.day, from: date))–\(calendar.component(.day, from: lastDay))"
            } else { label = format.string(from: date) }
            result.append(SpendingChartBucket(start: date, end: bucketEnd,
                amount: records.reduce(0) { $0 + $1.amount }, transactionCount: records.count,
                label: label, isInProgress: date <= referenceDate && referenceDate < bucketEnd))
            date = next
        }
        buckets = result
    }

    static func monthlyHistory(transactions: [Transaction], accountID: String, referenceDate: Date,
                               calendar: Calendar = .current) -> [SpendingChartBucket] {
        let start = calendar.dateInterval(of: .month, for: referenceDate)!.start
        let format = DateFormatter()
        format.calendar = calendar
        format.timeZone = calendar.timeZone
        format.setLocalizedDateFormatFromTemplate("MMM")
        return (-5...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            let snapshot = SpendingChartSnapshot(transactions: transactions, accountID: accountID,
                anchor: date, referenceDate: referenceDate, calendar: calendar)
            return SpendingChartBucket(start: snapshot.start, end: snapshot.end, amount: snapshot.total,
                transactionCount: snapshot.transactions.count, label: format.string(from: date),
                isInProgress: snapshot.isInProgress)
        }
    }
}
