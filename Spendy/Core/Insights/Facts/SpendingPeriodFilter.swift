import Foundation

struct SpendingPeriodFilter: Equatable {
    let month: Date

    init(month: Date, calendar: Calendar = .current) {
        self.month = calendar.dateInterval(of: .month, for: month)?.start ?? month
    }

    var title: String { month.formatted(.dateTime.month(.wide).year()) }

    func snapshot(transactions: [Transaction], accountID: String, referenceDate: Date,
                  transactionType: TransactionType = .expense, calendar: Calendar = .current) -> SpendingChartSnapshot {
        SpendingChartSnapshot(transactions: transactions, accountID: accountID, period: .month,
            anchor: month, referenceDate: referenceDate, calendar: calendar, transactionType: transactionType)
    }
}
