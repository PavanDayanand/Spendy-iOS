//
//  ExpenseStore.swift
//  Spendy
//
//  Observable Local-First Reactive Data Store and Persistence Engine
//

import SwiftUI
import Combine

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case system = "System"
    
    var id: String { rawValue }
    
    var sfSymbol: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.righthalf.filled"
        }
    }
}

@Observable
final class ExpenseStore {
    // MARK: - App State
    var userName: String = "" {
        didSet { saveToDisk() }
    }
    
    var soundEnabled: Bool = true {
        didSet { saveToDisk() }
    }
    
    var transactions: [Transaction] = [] {
        didSet { saveToDisk() }
    }
    
    var accounts: [Account] = [] {
        didSet { saveToDisk() }
    }
    
    var categories: [Category] = [] {
        didSet { saveToDisk() }
    }
    
    var subscriptions: [Subscription] = [] {
        didSet { saveToDisk() }
    }
    
    var budget: Budget = Budget() {
        didSet { saveToDisk() }
    }
    
    var currencySymbol: String = "₹" {
        didSet { saveToDisk() }
    }
    
    var currencyCode: String = "INR" {
        didSet { saveToDisk() }
    }
    
    var appearanceMode: AppearanceMode = .dark {
        didSet { saveToDisk() }
    }
    
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
    
    // MARK: - Initializer & Persistence
    init() {
        loadFromDisk()
    }
    
    private struct StoragePayload: Codable {
        var userName: String?
        var soundEnabled: Bool?
        var appearanceMode: AppearanceMode?
        var transactions: [Transaction]
        var accounts: [Account]
        var categories: [Category]
        var subscriptions: [Subscription]
        var budget: Budget
        var currencySymbol: String
        var currencyCode: String
    }
    
    private var storageURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("spendy_local_store.json")
    }
    
    private func loadFromDisk() {
        if FileManager.default.fileExists(atPath: storageURL.path) {
            do {
                let data = try Data(contentsOf: storageURL)
                let payload = try JSONDecoder().decode(StoragePayload.self, from: data)
                self.userName = payload.userName ?? ""
                self.soundEnabled = payload.soundEnabled ?? true
                self.appearanceMode = payload.appearanceMode ?? .dark
                self.transactions = payload.transactions
                self.accounts = payload.accounts
                self.categories = payload.categories
                self.subscriptions = payload.subscriptions
                self.budget = payload.budget
                self.currencySymbol = payload.currencySymbol
                self.currencyCode = payload.currencyCode
                return
            } catch {
                print("Failed to load local store: \(error.localizedDescription)")
            }
        }
        
        // Seed default initial state for first run
        seedInitialData()
    }
    
    private func saveToDisk() {
        do {
            let payload = StoragePayload(
                userName: userName,
                soundEnabled: soundEnabled,
                appearanceMode: appearanceMode,
                transactions: transactions,
                accounts: accounts,
                categories: categories,
                subscriptions: subscriptions,
                budget: budget,
                currencySymbol: currencySymbol,
                currencyCode: currencyCode
            )
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save local store: \(error.localizedDescription)")
        }
    }
    
    private func seedInitialData() {
        self.userName = "Pavan"
        self.soundEnabled = true
        self.appearanceMode = .dark
        self.accounts = Account.defaultAccounts
        self.categories = Category.defaultExpenseCategories + Category.defaultIncomeCategories
        self.subscriptions = []
        self.transactions = []
        self.budget = Budget()
        self.currencySymbol = "₹"
        self.currencyCode = "INR"
        saveToDisk()
    }
    
    // MARK: - Computed Properties
    
    /// Calculate current live balance for each account
    var accountBalances: [String: Double] {
        var balances: [String: Double] = [:]
        for account in accounts {
            balances[account.id] = account.openingBalance
        }
        
        for t in transactions {
            switch t.type {
            case .expense:
                balances[t.accountId, default: 0] -= t.amount
            case .income:
                balances[t.accountId, default: 0] += t.amount
            case .transfer:
                balances[t.accountId, default: 0] -= t.amount
                if let toId = t.toAccountId {
                    balances[toId, default: 0] += t.amount
                }
            }
        }
        return balances
    }
    
    /// Total Net Worth across all active accounts
    var totalBalance: Double {
        accountBalances.values.reduce(0, +)
    }
    
    /// Get balance for a specific account id (or total balance if nil / "all")
    func filteredBalance(for accountId: String?) -> Double {
        guard let id = accountId, id != "all" else {
            return totalBalance
        }
        return balance(for: id)
    }
    
    /// Get transactions filtered for a specific account (or all transactions if nil / "all")
    func filteredTransactions(for accountId: String?) -> [Transaction] {
        guard let id = accountId, id != "all" else {
            return transactions
        }
        return transactions.filter { $0.accountId == id || $0.toAccountId == id }
    }
    
    /// Transactions in the current calendar month
    var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
    }
    
    var monthlyIncome: Double {
        currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlyExpense: Double {
        currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlySavings: Double {
        monthlyIncome - monthlyExpense
    }
    
    var monthlySavingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        let rate = (monthlySavings / monthlyIncome) * 100
        return max(0, min(100, rate))
    }
    
    /// Recent transactions sorted by date descending
    var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }
    
    // MARK: - Lookup Helpers
    func category(for id: String) -> Category {
        if let found = categories.first(where: { $0.id == id }) {
            return found
        }
        return Category(
            id: id,
            label: id.capitalized,
            sfSymbol: SFIcons.wallet,
            colorHex: "#007AFF"
        )
    }
    
    func account(for id: String) -> Account {
        if let found = accounts.first(where: { $0.id == id }) {
            return found
        }
        return Account(
            id: id,
            label: id.capitalized,
            sfSymbol: SFIcons.bankAccount,
            colorHex: "#007AFF"
        )
    }
    
    func balance(for accountId: String) -> Double {
        accountBalances[accountId] ?? 0.0
    }
    
    // MARK: - Mutation Actions
    func setUserName(_ name: String) {
        self.userName = name
        HapticsManager.shared.trigger(.light)
    }
    
    func addTransaction(_ transaction: Transaction) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            transactions.insert(transaction, at: 0)
        }
        HapticsManager.shared.trigger(.success)
    }
    
    func deleteTransaction(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            transactions.removeAll(where: { $0.id == id })
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                transactions[index] = transaction
            }
            HapticsManager.shared.trigger(.light)
        }
    }
    
    func addAccount(_ account: Account) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            accounts.append(account)
        }
        HapticsManager.shared.trigger(.success)
    }
    
    func updateAccountName(id: String, newName: String) {
        if let index = accounts.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35)) {
                accounts[index].label = newName
            }
            HapticsManager.shared.trigger(.light)
        }
    }
    
    func updateAccountBalance(id: String, newBalance: Double) {
        if let index = accounts.firstIndex(where: { $0.id == id }) {
            let currentLiveBalance = balance(for: id)
            let delta = currentLiveBalance - accounts[index].openingBalance
            withAnimation(.spring(response: 0.35)) {
                accounts[index].openingBalance = newBalance - delta
            }
            HapticsManager.shared.trigger(.light)
        }
    }
    
    func deleteAccount(id: String, fallbackId: String? = nil) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if let fallbackId = fallbackId {
                for i in 0..<transactions.count {
                    if transactions[i].accountId == id {
                        transactions[i].accountId = fallbackId
                    }
                }
            }
            accounts.removeAll(where: { $0.id == id })
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func addCategory(_ category: Category) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            categories.append(category)
        }
        HapticsManager.shared.trigger(.success)
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            withAnimation(.spring(response: 0.35)) {
                categories[index] = category
            }
            HapticsManager.shared.trigger(.light)
        }
    }
    
    func deleteCategory(id: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            categories.removeAll(where: { $0.id == id })
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func addSubscription(_ subscription: Subscription) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            subscriptions.append(subscription)
        }
        HapticsManager.shared.trigger(.success)
    }
    
    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                subscriptions[index] = subscription
            }
            HapticsManager.shared.trigger(.light)
        }
    }
    
    func toggleSubscriptionPause(id: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if subscriptions[index].isPaused {
                    subscriptions[index].isPaused = false
                    subscriptions[index].status = "active"
                } else {
                    subscriptions[index].isPaused = true
                    subscriptions[index].status = "paused"
                }
            }
            HapticsManager.shared.trigger(.selection)
        }
    }
    
    func cancelSubscription(id: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                subscriptions[index].status = "cancelled"
            }
            HapticsManager.shared.trigger(.medium)
        }
    }
    
    func markSubscriptionAsPaid(id: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            let sub = subscriptions[index]
            let newTx = Transaction(
                title: sub.name,
                amount: sub.amount,
                type: .expense,
                categoryId: sub.categoryId,
                accountId: sub.accountId,
                date: Date(),
                notes: "Subscription payment for \(sub.name)"
            )
            addTransaction(newTx)
            
            let calendar = Calendar.current
            var nextDate = sub.nextBillingDate
            switch sub.cycle {
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = calendar.date(byAdding: .day, value: 7, to: nextDate) ?? nextDate
            }
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                subscriptions[index].nextBillingDate = nextDate
                if subscriptions[index].isTrial {
                    subscriptions[index].isTrial = false
                }
            }
        }
    }
    
    func keepSubscription(id: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                subscriptions[index].isTrial = false
                subscriptions[index].status = "active"
            }
            markSubscriptionAsPaid(id: id)
        }
    }
    
    func deleteSubscription(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            subscriptions.removeAll(where: { $0.id == id })
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    // MARK: - Budget Calculations & Cycle Ranges
    
    /// Calculate the start of the budget cycle based on configured startDay and period
    func budgetCycleStart(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let targetDay = min(max(budget.startDay, 1), 28)
        
        var components = DateComponents()
        components.year = year
        components.day = targetDay
        
        if budget.period == .yearly {
            components.month = 1
            guard let candidate = calendar.date(from: components) else { return date }
            if date < candidate {
                components.year = year - 1
                return calendar.date(from: components) ?? date
            }
            return candidate
        } else {
            components.month = month
            guard let candidate = calendar.date(from: components) else { return date }
            if date < candidate {
                components.month = month == 1 ? 12 : month - 1
                if month == 1 { components.year = year - 1 }
                return calendar.date(from: components) ?? date
            }
            return candidate
        }
    }
    
    /// Calculate the end of the budget cycle
    func budgetCycleEnd(for date: Date = Date()) -> Date {
        let start = budgetCycleStart(for: date)
        let calendar = Calendar.current
        if budget.period == .yearly {
            return calendar.date(byAdding: .year, value: 1, to: start) ?? start
        } else {
            return calendar.date(byAdding: .month, value: 1, to: start) ?? start
        }
    }
    
    /// Total expenses within current active budget cycle
    var budgetCycleExpenses: Double {
        guard budget.isActive else { return 0.0 }
        let start = budgetCycleStart()
        let end = budgetCycleEnd()
        return transactions
            .filter { $0.type == .expense && $0.date >= start && $0.date < end }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    /// Target budget amount scaled for the selected view period (monthly vs yearly)
    func budgetTargetAmount(for viewPeriod: BudgetPeriod) -> Double {
        guard budget.isActive, budget.amount > 0 else { return 0.0 }
        if budget.period == .yearly && viewPeriod == .monthly {
            return budget.amount / 12.0
        } else if budget.period == .monthly && viewPeriod == .yearly {
            return budget.amount * 12.0
        }
        return budget.amount
    }
    
    /// Days left in the current budget cycle
    var budgetDaysLeft: Int {
        guard budget.isActive else { return 0 }
        let end = budgetCycleEnd()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: end))
        return max(0, components.day ?? 0)
    }
    
    /// Total expenses incurred today
    var todayExpenses: Double {
        let calendar = Calendar.current
        return transactions
            .filter { $0.type == .expense && calendar.isDateInToday($0.date) }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    /// Safe daily allowance remaining for today
    var leftToday: Double {
        let target = budgetTargetAmount(for: budget.period)
        let days = max(1, budgetDaysLeft)
        let safeDaily = max(0.0, (target - budgetCycleExpenses) / Double(days))
        return max(0.0, safeDaily - todayExpenses)
    }
    
    /// Total expenses over the last 30 days
    var last30DaysExpenses: Double {
        let now = Date()
        let calendar = Calendar.current
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return 0.0 }
        return transactions
            .filter { $0.type == .expense && $0.date >= thirtyDaysAgo && $0.date <= now }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    /// Recommended budget based on average of last 3 active months
    var recommendedBudget: Double? {
        let calendar = Calendar.current
        let now = Date()
        var monthTotals: [Double] = []
        
        for offset in 1...3 {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { continue }
            
            let total = transactions
                .filter { $0.type == .expense && $0.date >= start && $0.date <= end }
                .reduce(0.0) { $0 + $1.amount }
            if total > 0 {
                monthTotals.append(total)
            }
        }
        
        guard !monthTotals.isEmpty else { return nil }
        let avg = monthTotals.reduce(0.0, +) / Double(monthTotals.count)
        return max(100.0, (avg / 100.0).rounded() * 100.0)
    }
    
    /// Total amount currently assigned across all category budgets
    var totalAllocatedCategoryBudgets: Double {
        budget.categoryBudgets.values.reduce(0.0, +)
    }
    
    /// Remaining unallocated budget available for categories
    var availableToAllocate: Double {
        let target = budgetTargetAmount(for: budget.period)
        return max(0.0, target - totalAllocatedCategoryBudgets)
    }
    
    enum BudgetPacingState {
        case onTrack
        case overPace(deltaPct: Int)
        case underPace(deltaPct: Int)
        case exceeded(excessAmount: Double)
        
        var title: String {
            switch self {
            case .onTrack: return "On Track"
            case .overPace(let pct): return "Over Pace (+\(pct)%)"
            case .underPace(let pct): return "Under Pace (-\(pct)%)"
            case .exceeded: return "Budget Exceeded"
            }
        }
        
        var colorHex: String {
            switch self {
            case .onTrack: return "#30D158"
            case .overPace: return "#FF9500"
            case .underPace: return "#30D158"
            case .exceeded: return "#FF453A"
            }
        }
    }
    
    /// Calculate current pacing status comparing actual time elapsed vs actual money spent
    var budgetPacingState: BudgetPacingState {
        let target = budgetTargetAmount(for: budget.period)
        guard budget.isActive, target > 0 else { return .onTrack }
        let spent = budgetCycleExpenses
        
        if spent > target {
            return .exceeded(excessAmount: spent - target)
        }
        
        let start = budgetCycleStart()
        let end = budgetCycleEnd()
        let calendar = Calendar.current
        let totalDays = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 30)
        let elapsedDays = max(1, calendar.dateComponents([.day], from: start, to: Date()).day ?? 1)
        
        let timePct = (Double(elapsedDays) / Double(totalDays)) * 100.0
        let spendPct = (spent / target) * 100.0
        let delta = spendPct - timePct
        
        if delta > 12 {
            return .overPace(deltaPct: Int(round(delta)))
        } else if delta < -12 {
            return .underPace(deltaPct: Int(round(abs(delta))))
        } else {
            return .onTrack
        }
    }
    
    /// Projected budget exhaustion information and pacing insight message
    var budgetPacingInsightMessage: String? {
        let target = budgetTargetAmount(for: budget.period)
        guard budget.isActive, target > 0 else { return nil }
        
        let start = budgetCycleStart()
        let calendar = Calendar.current
        let elapsedDays = max(1, calendar.dateComponents([.day], from: start, to: Date()).day ?? 1)
        let spent = budgetCycleExpenses
        
        if spent > target {
            let excess = spent - target
            return "At this pace, your budget is exceeded by \(excess.formattedCurrency(symbol: currencySymbol, decimals: 0))."
        }
        
        let avgDaily = spent / Double(elapsedDays)
        guard avgDaily > 0 else { return "Pacing comfortably within your safe daily target." }
        
        let projectedDaysToExhaust = target / avgDaily
        guard let projectedExhaustionDate = calendar.date(byAdding: .day, value: Int(projectedDaysToExhaust), to: start) else { return nil }
        
        let end = budgetCycleEnd()
        if projectedExhaustionDate < end {
            let daysEarly = max(1, calendar.dateComponents([.day], from: projectedExhaustionDate, to: end).day ?? 1)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "At your current pace (\(avgDaily.formattedCurrency(symbol: currencySymbol, decimals: 0))/day), budget runs out on \(formatter.string(from: projectedExhaustionDate)) (\(daysEarly) \(daysEarly == 1 ? "day" : "days") early)."
        } else {
            return "Pacing smoothly! You are projected to finish the cycle under budget."
        }
    }

    /// What-If projected total cycle expenses
    func customProjectedExpenses(dailySpend: Double) -> Double {
        let days = budgetDaysLeft
        return budgetCycleExpenses + (dailySpend * Double(days))
    }
    
    /// What-If projected cycle end net balance
    func customProjectedEndBalance(dailySpend: Double) -> Double {
        let projectedExp = customProjectedExpenses(dailySpend: dailySpend)
        let target = budgetTargetAmount(for: budget.period)
        return target - projectedExp
    }

    // MARK: - Budget Mutation Actions
    
    func setBudget(amount: Double, period: BudgetPeriod, startDay: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            budget.amount = amount
            budget.period = period
            budget.startDay = min(max(startDay, 1), 28)
            budget.isActive = true
        }
        HapticsManager.shared.trigger(.success)
    }
    
    func deleteBudget() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            budget.isActive = false
            budget.amount = 0.0
            budget.categoryBudgets = [:]
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func updateCategoryBudget(categoryId: String, limit: Double) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if limit <= 0 {
                budget.categoryBudgets.removeValue(forKey: categoryId)
            } else {
                budget.categoryBudgets[categoryId] = limit
            }
        }
        HapticsManager.shared.trigger(.light)
    }
    
    func removeCategoryBudget(categoryId: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            budget.categoryBudgets.removeValue(forKey: categoryId)
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func updateCurrency(symbol: String, code: String) {
        self.currencySymbol = symbol
        self.currencyCode = code
        HapticsManager.shared.trigger(.selection)
    }

    
    func resetToSampleData() {
        seedInitialData()
    }
    
    func clearAllTransactions() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.transactions = []
        }
    }
    
    func exportJSONData() -> Data? {
        let payload = StoragePayload(
            userName: userName,
            soundEnabled: soundEnabled,
            transactions: transactions,
            accounts: accounts,
            categories: categories,
            subscriptions: subscriptions,
            budget: budget,
            currencySymbol: currencySymbol,
            currencyCode: currencyCode
        )
        return try? JSONEncoder().encode(payload)
    }
    
    func importJSONData(data: Data) -> Bool {
        do {
            let payload = try JSONDecoder().decode(StoragePayload.self, from: data)
            withAnimation(.spring(response: 0.35)) {
                self.userName = payload.userName ?? self.userName
                self.soundEnabled = payload.soundEnabled ?? self.soundEnabled
                self.transactions = payload.transactions
                self.accounts = payload.accounts
                self.categories = payload.categories
                self.subscriptions = payload.subscriptions
                self.budget = payload.budget
                self.currencySymbol = payload.currencySymbol
                self.currencyCode = payload.currencyCode
            }
            HapticsManager.shared.trigger(.success)
            return true
        } catch {
            print("Failed to import JSON data: \(error.localizedDescription)")
            HapticsManager.shared.trigger(.error)
            return false
        }
    }
}
