//
//  WidgetDataManager+Store.swift
//  Spendy
//
//  Publishes live store data into the App Group for widgets and intents.
//

import Foundation

extension WidgetDataManager {
    @MainActor
    func publish(from store: ExpenseStore) {
        guard store.loadError == nil else { return }
        do {
            try ReceiptShareStore.publish(ReceiptShareContext(currencySymbol: store.currencySymbol,
                currencyCode: store.currencyCode, categories: store.categories, accounts: store.accounts,
                balances: Dictionary(uniqueKeysWithValues: store.accounts.map { ($0.id, store.balance(for: $0.id)) })))
        } catch {
            store.sharedReceiptImportError = "Receipt actions are unavailable. \(error.localizedDescription)"
        }
        updateSnapshot(from: store)
        NotificationManager.shared.refresh(from: store)
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

        // Compare elapsed time with the same point last month. Skip months that
        // lack the equivalent calendar day or have no prior spending to compare.
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now.startOfMonth
        let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        let currentDay = calendar.component(.day, from: now)
        let priorMonthDays = calendar.range(of: .day, in: .month, for: previousMonthStart)?.count ?? 0
        let secondsSinceMidnight = calendar.component(.hour, from: now) * 3600
            + calendar.component(.minute, from: now) * 60
            + calendar.component(.second, from: now)
        let previousMonthToDateTotal: Double? = {
            guard currentDay <= priorMonthDays,
                  let previousDay = calendar.date(byAdding: .day, value: currentDay - 1, to: previousMonthStart),
                  let previousCutoff = calendar.date(byAdding: .second, value: secondsSinceMidnight, to: previousDay)
            else { return nil }
            let priorExpenses = store.transactions.filter {
                $0.type == .expense && $0.date >= previousMonthStart && $0.date <= previousCutoff
            }
            guard !priorExpenses.isEmpty else { return nil }
            return priorExpenses.reduce(0) { $0 + $1.amount }
        }()

        let budgetLimit = store.budgetTargetAmount(for: store.budget.period)
        let budgetSpent = store.budgetCycleExpenses
        let remainingBudget = max(0, budgetLimit - budgetSpent)
        let budgetOverage = budgetLimit > 0 ? max(0, budgetSpent - budgetLimit) : 0
        let budgetProgress = budgetLimit > 0 ? min(1, max(0, budgetSpent / budgetLimit)) : 0

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
                    isToday: calendar.isDateInToday(targetDate),
                    dayStart: calendar.startOfDay(for: targetDate)
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

        let categorySpending: [WidgetCategorySpend] = catSpendMap
            .sorted { $0.value > $1.value }
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
        let topCategories = Array(categorySpending.prefix(3))

        let daysLeft = store.budgetDaysLeft
        let dailyPace = daysLeft > 0 ? (remainingBudget / Double(daysLeft)) : remainingBudget
        let pacingCaption = budgetLimit > 0
            ? (budgetOverage > 0
                ? "Over budget by \(SpendyWidgetFormat.compactAmount(budgetOverage, symbol: store.currencySymbol))"
                : "\(SpendyWidgetFormat.compactAmount(dailyPace, symbol: store.currencySymbol)) per day left")
            : "No active budget"

        let snapshot = SpendyWidgetSnapshot(
            currencySymbol: store.currencySymbol,
            currencyCode: store.currencyCode,
            defaultAccountId: store.accounts.first?.id ?? "bank",
            todayTotal: todayTotal,
            todayIncome: todayIncome,
            monthTotal: monthTotal,
            previousMonthToDateTotal: previousMonthToDateTotal,
            remainingBudget: remainingBudget,
            budgetTotal: budgetLimit,
            budgetProgress: budgetProgress,
            budgetOverage: budgetOverage,
            budgetPeriod: store.budget.period.rawValue,
            budgetCycleEnd: store.budget.isActive ? store.budgetCycleEnd() : nil,
            topCategoryName: topCategory?.label ?? "None",
            topCategorySymbol: topCategory?.sfSymbol ?? "tag.fill",
            topCategoryColorHex: topCategory?.colorHex ?? "#007AFF",
            topCategoryAmount: topCatAmount,
            weeklySpending: weeklyPoints,
            recentTransactions: recentItems,
            topCategories: topCategories,
            categorySpending: categorySpending,
            daysLeft: daysLeft,
            pacingCaption: pacingCaption,
            lastUpdated: now
        )

        saveSnapshot(snapshot)
    }
}
