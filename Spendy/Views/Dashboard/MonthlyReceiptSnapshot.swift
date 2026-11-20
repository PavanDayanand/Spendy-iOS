import Foundation

/// The same monthly report feeds the onscreen paper and its share image.
struct MonthlyReceiptSnapshot: Hashable {
    let month: Date
    let currencySymbol: String
    let income: Double
    let expenses: Double
    let transactionCount: Int
    let categories: [MonthlyReceiptCategory]

    var title: String { month.formatted(.dateTime.month(.wide).year()) }

    init(month: Date, transactions: [Transaction], categories: [Category], currencySymbol: String) {
        self.month = month
        self.currencySymbol = currencySymbol
        let calendar = Calendar.current
        let selected = transactions.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
        income = selected.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        expenses = selected.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        transactionCount = selected.count
        let totals = Dictionary(grouping: selected.filter { $0.type == .expense }, by: \.categoryId)
        self.categories = totals.map { id, transactions in
            MonthlyReceiptCategory(id: id, name: categories.first { $0.id == id }?.label ?? "Other",
                                   amount: transactions.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount == $1.amount ? $0.name < $1.name : $0.amount > $1.amount }
    }
}
