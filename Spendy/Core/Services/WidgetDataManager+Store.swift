//
//  WidgetDataManager+Store.swift
//  Spendy
//
//  Publishes live store data into the App Group for widgets, intents, and Live Activities.
//

import Foundation

extension WidgetDataManager {
    @MainActor
    func publish(from store: ExpenseStore) {
        updateSnapshot(from: store)
        saveCategories(store.categories.map { category in
            WidgetCategoryRecord(
                id: category.id,
                name: category.label,
                sfSymbol: category.sfSymbol,
                colorHex: category.colorHex,
                isExpense: category.type != .income,
                isHidden: category.isHidden,
                order: category.order
            )
        })
        saveAccounts(store.accounts.map { account in
            WidgetAccountRecord(
                id: account.id,
                name: account.label,
                sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                colorHex: account.colorHex,
                order: account.order
            )
        })
        
        // Sync Dynamic Island & Lock Screen Live Activities
        SpendyLiveActivityManager.shared.syncLiveActivity(from: store)
    }

    @MainActor
    func updateSnapshot(from store: ExpenseStore) {
        let calendar = Calendar.current
        let now = Date()

        let todayExpenses = store.transactions.filter {
            $0.type == .expense && calendar.isDateInToday($0.date)
        }
        let todayTotal = todayExpenses.reduce(0) { $0 + $1.amount }

        let todayIncome = store.transactions.filter {
            $0.type == .income && calendar.isDateInToday($0.date)
        }.reduce(0) { $0 + $1.amount }

        let currentMonthExpenses = store.transactions.filter {
            $0.type == .expense && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let monthTotal = currentMonthExpenses.reduce(0) { $0 + $1.amount }

        let budgetLimit = store.budget.amount > 0 ? store.budget.amount : 0
        let remainingBudget = max(0, budgetLimit - monthTotal)
        let budgetProgress = budgetLimit > 0 ? min(1, max(0, monthTotal / budgetLimit)) : 0

        var catSpendMap: [String: Double] = [:]
        for tx in currentMonthExpenses {
            catSpendMap[tx.categoryId, default: 0] += tx.amount
        }
        let topCatId = catSpendMap.max(by: { $0.value < $1.value })?.key
        let topCatAmount = topCatId.flatMap { catSpendMap[$0] } ?? 0
        let topCategory = topCatId.flatMap { id in store.categories.first(where: { $0.id == id }) }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        var weeklyPoints: [WidgetDaySpending] = []
        for dayOffset in (0..<7).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let daySum = store.transactions.filter {
                $0.type == .expense && calendar.isDate($0.date, inSameDayAs: targetDate)
            }.reduce(0) { $0 + $1.amount }
            weeklyPoints.append(
                WidgetDaySpending(
                    dayLabel: String(dayFormatter.string(from: targetDate).prefix(1)),
                    amount: daySum,
                    isToday: calendar.isDateInToday(targetDate)
                )
            )
        }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let recentItems: [WidgetTransactionItem] = store.transactions.prefix(3).map { tx in
            let cat = store.categories.first(where: { $0.id == tx.categoryId })
            return WidgetTransactionItem(
                id: tx.id.uuidString,
                title: tx.title,
                amount: tx.amount,
                isExpense: tx.type == .expense,
                categorySymbol: cat?.sfSymbol ?? "tag.fill",
                categoryColorHex: cat?.colorHex ?? "#007AFF",
                formattedTime: timeFormatter.string(from: tx.date)
            )
        }

        let topCategories: [WidgetCategorySpend] = catSpendMap
            .sorted { $0.value > $1.value }
            .prefix(3)
            .compactMap { pair -> WidgetCategorySpend? in
                guard let cat = store.categories.first(where: { $0.id == pair.key }) else { return nil }
                return WidgetCategorySpend(
                    id: pair.key,
                    name: cat.label,
                    sfSymbol: cat.sfSymbol,
                    colorHex: cat.colorHex,
                    amount: pair.value
                )
            }

        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let currentDay = calendar.component(.day, from: now)
        let daysLeft = max(0, daysInMonth - currentDay)
        let dailyPace = daysLeft > 0 ? (remainingBudget / Double(daysLeft)) : remainingBudget
        let pacingCaption = budgetLimit > 0
            ? "\(SpendyWidgetFormat.compactAmount(dailyPace, symbol: store.currencySymbol))/day left"
            : "\(SpendyWidgetFormat.compactAmount(todayTotal, symbol: store.currencySymbol)) spent today"

        let snapshot = SpendyWidgetSnapshot(
            currencySymbol: store.currencySymbol,
            currencyCode: store.currencyCode,
            defaultAccountId: store.accounts.first?.id ?? "bank",
            todayTotal: todayTotal,
            todayIncome: todayIncome,
            monthTotal: monthTotal,
            remainingBudget: remainingBudget,
            budgetTotal: budgetLimit,
            budgetProgress: budgetProgress,
            topCategoryName: topCategory?.label ?? "None",
            topCategorySymbol: topCategory?.sfSymbol ?? "tag.fill",
            topCategoryColorHex: topCategory?.colorHex ?? "#007AFF",
            topCategoryAmount: topCatAmount,
            weeklySpending: weeklyPoints,
            recentTransactions: recentItems,
            topCategories: topCategories,
            daysLeft: daysLeft,
            pacingCaption: pacingCaption,
            lastUpdated: now
        )

        saveSnapshot(snapshot)
    }
}
