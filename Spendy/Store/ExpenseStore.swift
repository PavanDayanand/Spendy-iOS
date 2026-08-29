//
//  ExpenseStore.swift
//  Spendy
//
//  Observable Local-First Reactive Data Store and Persistence Engine
//

import SwiftUI
import Combine
import Observation

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
    
    var hapticsEnabled: Bool = true {
        didSet {
            HapticsManager.shared.isEnabled = hapticsEnabled
            saveToDisk()
        }
    }
    
    var profileImageData: Data? = nil {
        didSet { saveToDisk() }
    }
    
    var profileIconSymbol: String? = nil {
        didSet { saveToDisk() }
    }
    
    var profileColorHex: String? = nil {
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
    
    var customFolders: [Folder] = [] {
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
    
    var ratesToUSD: [String: Double] = [
        "USD": 1.0,
        "INR": 86.85,
        "EUR": 0.95,
        "GBP": 0.79,
        "JPY": 152.40,
        "CAD": 1.41,
        "AUD": 1.55,
        "AED": 3.67,
        "SGD": 1.34
    ] {
        didSet { saveToDisk() }
    }
    
    var appearanceMode: AppearanceMode = .dark {
        didSet { saveToDisk() }
    }
    
    var colorScheme: ColorScheme? {
        return .dark
    }
    
    var isGradientBackgroundEnabled: Bool = true {
        didSet { saveToDisk() }
    }
    
    var topGradientHue: Double = 0.60 {
        didSet {
            updateGradientHexFromHSB()
            saveToDisk()
        }
    }
    
    var topGradientBrightness: Double = 0.85 {
        didSet {
            updateGradientHexFromHSB()
            saveToDisk()
        }
    }
    
    var topGradientColorHex: String = "#007AFF" {
        didSet { saveToDisk() }
    }
    
    var topGradientColor: Color {
        Color(hue: topGradientHue, saturation: 0.90, brightness: min(max(topGradientBrightness, 0.20), 0.98))
    }
    
    private func updateGradientHexFromHSB() {
        let uiColor = UIColor(hue: topGradientHue, saturation: 0.90, brightness: min(max(topGradientBrightness, 0.20), 0.95), alpha: 1.0)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            self.topGradientColorHex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }
    
    func setTopGradientColor(_ color: Color) {
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            self.topGradientHue = Double(h)
            self.topGradientBrightness = Double(min(max(b, 0.20), 0.95))
        } else {
            let clamped = color.clampedToDarkModeAccent()
            self.topGradientColorHex = clamped.toHex()
        }
    }
    
    // MARK: - Initializer & Persistence
    init() {
        loadFromDisk()
        fetchLiveRates()
        HapticsManager.shared.isEnabled = hapticsEnabled
    }
    
    private struct StoragePayload: Codable {
        var userName: String?
        var hapticsEnabled: Bool?
        var profileImageData: Data?
        var profileIconSymbol: String?
        var profileColorHex: String?
        var soundEnabled: Bool?
        var appearanceMode: AppearanceMode?
        var topGradientColorHex: String?
        var isGradientBackgroundEnabled: Bool?
        var topGradientHue: Double?
        var topGradientBrightness: Double?
        var transactions: [Transaction]
        var accounts: [Account]
        var categories: [Category]
        var subscriptions: [Subscription]
        var budget: Budget
        var currencySymbol: String
        var currencyCode: String
        var customFolders: [Folder]?
        var ratesToUSD: [String: Double]?
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
                self.hapticsEnabled = payload.hapticsEnabled ?? true
                self.profileImageData = payload.profileImageData
                self.profileIconSymbol = payload.profileIconSymbol
                self.profileColorHex = payload.profileColorHex
                self.soundEnabled = payload.soundEnabled ?? true
                self.appearanceMode = .dark
                self.topGradientColorHex = payload.topGradientColorHex ?? "#007AFF"
                self.isGradientBackgroundEnabled = payload.isGradientBackgroundEnabled ?? true
                self.topGradientHue = payload.topGradientHue ?? 0.60
                self.topGradientBrightness = payload.topGradientBrightness ?? 0.85
                self.transactions = payload.transactions
                self.accounts = payload.accounts
                self.categories = payload.categories
                self.subscriptions = payload.subscriptions
                self.budget = payload.budget
                self.currencySymbol = payload.currencySymbol
                self.currencyCode = payload.currencyCode
                self.customFolders = payload.customFolders ?? []
                self.ratesToUSD = payload.ratesToUSD ?? [
                    "USD": 1.0,
                    "INR": 86.85,
                    "EUR": 0.95,
                    "GBP": 0.79,
                    "JPY": 152.40,
                    "CAD": 1.41,
                    "AUD": 1.55,
                    "AED": 3.67,
                    "SGD": 1.34
                ]
                // Migration: Ensure seeded accounts are typed
                for i in 0..<self.accounts.count {
                    if self.accounts[i].id == "cash" {
                        self.accounts[i].type = .cash
                    }
                }
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
                hapticsEnabled: hapticsEnabled,
                profileImageData: profileImageData,
                profileIconSymbol: profileIconSymbol,
                profileColorHex: profileColorHex,
                soundEnabled: soundEnabled,
                appearanceMode: .dark,
                topGradientColorHex: topGradientColorHex,
                isGradientBackgroundEnabled: isGradientBackgroundEnabled,
                topGradientHue: topGradientHue,
                topGradientBrightness: topGradientBrightness,
                transactions: transactions,
                accounts: accounts,
                categories: categories,
                subscriptions: subscriptions,
                budget: budget,
                currencySymbol: currencySymbol,
                currencyCode: currencyCode,
                customFolders: customFolders,
                ratesToUSD: ratesToUSD
            )
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save local store: \(error.localizedDescription)")
        }
    }
    
    private func seedInitialData() {
        self.userName = ""
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
    
    var netWorthChangePercentage: Double {
        let now = Date()
        let calendar = Calendar.current
        guard let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return 0.0 }
        guard let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) else { return 0.0 }
        
        let lastMonthTxs = transactions.filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }
        let netLastMonth = lastMonthTxs.map { $0.type == .income ? $0.amount : -$0.amount }.reduce(0, +)
        
        let currentNet = totalBalance
        let previousNet = currentNet - netLastMonth
        guard previousNet > 0 else { return 0.0 }
        return (netLastMonth / previousNet) * 100.0
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
    
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            withAnimation(.spring(response: 0.35)) {
                accounts[index] = account
            }
            HapticsManager.shared.trigger(.light)
        }
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
    
    func addFolder(_ folder: Folder) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            customFolders.append(folder)
        }
        HapticsManager.shared.trigger(.success)
    }
    
    func updateFolder(_ folder: Folder, oldName: String) {
        withAnimation(.spring(response: 0.35)) {
            if let index = customFolders.firstIndex(where: { $0.id == folder.id }) {
                customFolders[index] = folder
            } else {
                customFolders.append(folder)
            }
            // Also update any categories that were in the old folder to the new folder name
            for catIndex in categories.indices {
                if categories[catIndex].folder == oldName && categories[catIndex].type == folder.type {
                    categories[catIndex].folder = folder.name
                }
            }
        }
        HapticsManager.shared.trigger(.light)
    }
    
    func deleteFolder(id: String, name: String? = nil, type: TransactionType? = nil) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let targetName = name ?? customFolders.first(where: { $0.id == id })?.name
            let targetType = type ?? customFolders.first(where: { $0.id == id })?.type
            
            if let folderName = targetName {
                for index in categories.indices {
                    if categories[index].folder == folderName && (targetType == nil || categories[index].type == targetType) {
                        categories[index].folder = "Uncategorized"
                    }
                }
            }
            customFolders.removeAll(where: { $0.id == id || (targetName != nil && $0.name == targetName) })
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
        
        if budget.period == .weekly {
            let currentWeekday = calendar.component(.weekday, from: date)
            let diff = (currentWeekday - budget.startDay + 7) % 7
            let startOfDay = calendar.startOfDay(for: date)
            return calendar.date(byAdding: .day, value: -diff, to: startOfDay) ?? date
        } else {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let targetDay = min(max(budget.startDay, 1), 28)
            
            var components = DateComponents()
            components.year = year
            components.day = targetDay
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
        if budget.period == .weekly {
            return calendar.date(byAdding: .day, value: 7, to: start) ?? start
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
    
    /// Target budget amount scaled for the selected view period (monthly vs weekly)
    func budgetTargetAmount(for viewPeriod: BudgetPeriod) -> Double {
        guard budget.isActive, budget.amount > 0 else { return 0.0 }
        if budget.period == .weekly && viewPeriod == .monthly {
            return budget.amount * 4.3333
        } else if budget.period == .monthly && viewPeriod == .weekly {
            return budget.amount / 4.3333
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
    
    /// Safe daily average allowance for remaining days in cycle
    var safeDailyAllowance: Double {
        let target = budgetTargetAmount(for: budget.period)
        let days = max(1, budgetDaysLeft)
        return max(0.0, (target - budgetCycleExpenses) / Double(days))
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
        
        let timePct = totalDays > 0 ? (Double(elapsedDays) / Double(totalDays)) * 100.0 : 0.0
        let spendPct = target > 0 ? (spent / target) * 100.0 : 0.0
        let delta = spendPct - timePct
        
        if delta > 12 {
            return .overPace(deltaPct: round(delta).safeInt)
        } else if delta < -12 {
            return .underPace(deltaPct: round(abs(delta)).safeInt)
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
        let daysVal = min(365.0, max(0.0, projectedDaysToExhaust)).safeInt
        guard let projectedExhaustionDate = calendar.date(byAdding: .day, value: daysVal, to: start) else { return nil }
        
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
        budget.categoryBudgets.removeValue(forKey: categoryId)
        HapticsManager.shared.trigger(.medium)
    }
    
    func updateCurrency(symbol: String, code: String) {
        self.currencySymbol = symbol
        self.currencyCode = code
        HapticsManager.shared.trigger(.selection)
    }
    
    func fetchLiveRates() {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data, error == nil else { return }
            do {
                struct APIResponse: Codable {
                    let result: String
                    let rates: [String: Double]
                }
                let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
                if decoded.result == "success" {
                    DispatchQueue.main.async {
                        var updatedRates = self.ratesToUSD
                        for (code, rate) in decoded.rates {
                            updatedRates[code] = rate
                        }
                        self.ratesToUSD = updatedRates
                        self.saveToDisk()
                    }
                }
            } catch {
                print("Failed to decode currency rates: \(error)")
            }
        }.resume()
    }

    
    func resetToSampleData() {
        seedInitialData()
    }
    
    func eraseAllData() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.transactions = []
            self.subscriptions = []
            self.customFolders = []
            self.budget = Budget()
            self.userName = ""
            // Re-seed default accounts and categories so the app is immediately usable
            self.accounts = Account.defaultAccounts
            self.categories = Category.defaultExpenseCategories + Category.defaultIncomeCategories
        }
        saveToDisk()
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
            if importWebExportJSON(data: data) {
                return true
            }
            print("Failed to import JSON data: \(error.localizedDescription)")
            HapticsManager.shared.trigger(.error)
            return false
        }
    }
    
    private func importWebExportJSON(data: Data) -> Bool {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFormatterNoFrac = ISO8601DateFormatter()
        isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
        
        func parseDate(_ str: String) -> Date {
            if let d = isoFormatter.date(from: str) { return d }
            if let d = isoFormatterNoFrac.date(from: str) { return d }
            return Date()
        }
        
        func parseUUID(_ str: String) -> UUID {
            var clean = str
            if clean.hasPrefix("tx_") { clean = String(clean.dropFirst(3)) }
            else if clean.hasPrefix("trans_") { clean = String(clean.dropFirst(6)) }
            else if clean.hasPrefix("sub_") { clean = String(clean.dropFirst(4)) }
            return UUID(uuidString: clean) ?? UUID()
        }
        
        let importedUserName = jsonObject["userName"] as? String
        let importedCurrency = jsonObject["currency"] as? String
        
        var newBudget = self.budget
        if let bDict = jsonObject["budget"] as? [String: Any] {
            let amt = (bDict["amount"] as? NSNumber)?.doubleValue ?? 0.0
            let periodStr = bDict["period"] as? String ?? "monthly"
            let period = BudgetPeriod(rawValue: periodStr) ?? .monthly
            let startDay = bDict["startDay"] as? Int ?? 1
            let isActive = bDict["isActive"] as? Bool ?? (amt > 0)
            newBudget = Budget(amount: amt, period: period, startDay: startDay, isActive: isActive)
        }
        
        var newAccounts: [Account] = []
        if let accArray = jsonObject["accounts"] as? [[String: Any]] {
            for (idx, dict) in accArray.enumerated() {
                guard let id = dict["id"] as? String, let label = dict["label"] as? String else { continue }
                let icon = dict["icon"] as? String ?? ""
                let symbol: String = {
                    if icon.contains("🏦") { return SFIcons.bankAccount }
                    if icon.contains("💵") { return SFIcons.cashAccount }
                    return SFIcons.bankAccount
                }()
                let defaultColor: String = {
                    if id.lowercased().contains("cash") { return "#30D158" }
                    if id.lowercased() == "bank" { return "#18181B" }
                    return "#007AFF"
                }()
                let opBal = (dict["openingBalance"] as? NSNumber)?.doubleValue ?? 0.0
                newAccounts.append(Account(id: id, label: label, sfSymbol: symbol, colorHex: defaultColor, openingBalance: opBal, order: idx))
            }
        }
        
        var newCategories: [Category] = []
        if let catObj = jsonObject["categories"] as? [String: Any] {
            let sfMap: [String: String] = [
                "fastfood": "fork.knife",
                "gas": "fuelpump.fill",
                "groceries": "cart.fill",
                "movies": "popcorn.fill",
                "savings": "piggybank.fill",
                "receipt": "receipt",
                "spa": "leaf.fill",
                "pets": "pawprint.fill",
                "home": "house.fill",
                "amazon": "shippingbox.fill",
                "cut": "scissors",
                "golf": "car.fill",
                "favorite": "heart.fill",
                "drycleaning": "bag.fill",
                "glasses": "eyeglasses",
                "brush": "pencil.and.ruler.fill",
                "atm": "creditcard.fill",
                "money": "dollarsign.circle.fill",
                "work": "briefcase.fill",
                "gift": "gift.fill",
                "family": "figure.2.and.child.holdinghands",
                "Tag": "tag.fill"
            ]
            
            func parseCatList(_ list: [[String: Any]], _ type: TransactionType) {
                for (idx, dict) in list.enumerated() {
                    guard let id = dict["id"] as? String, let label = dict["label"] as? String else { continue }
                    let color = dict["color"] as? String ?? "#3478f6"
                    let iconName = dict["iconName"] as? String ?? ""
                    let symbol = sfMap[iconName] ?? "tag.fill"
                    let hidden = dict["hidden"] as? Bool ?? false
                    let folder = dict["folder"] as? String ?? "Uncategorized"
                    newCategories.append(Category(id: id, label: label, sfSymbol: symbol, colorHex: color, type: type, folder: folder, isHidden: hidden, order: idx))
                }
            }
            
            if let expList = catObj["expense"] as? [[String: Any]] {
                parseCatList(expList, .expense)
            }
            if let incList = catObj["income"] as? [[String: Any]] {
                parseCatList(incList, .income)
            }
        }
        
        var newSubscriptions: [Subscription] = []
        if let subArray = jsonObject["subscriptions"] as? [[String: Any]] {
            for dict in subArray {
                guard let idStr = dict["id"] as? String,
                      let name = dict["name"] as? String,
                      let amtNum = dict["amount"] as? NSNumber else { continue }
                let cycleStr = dict["cycle"] as? String ?? "monthly"
                let cycle = BillingCycle(rawValue: cycleStr) ?? .monthly
                let dateStr = (dict["nextBilling"] as? String) ?? (dict["originalDate"] as? String) ?? ""
                let date = parseDate(dateStr)
                let accountId = dict["accountId"] as? String ?? "bank"
                let isTrial = dict["isTrial"] as? Bool ?? false
                let status = dict["status"] as? String ?? "active"
                
                newSubscriptions.append(Subscription(
                    id: parseUUID(idStr),
                    name: name,
                    amount: amtNum.doubleValue,
                    cycle: cycle,
                    nextBillingDate: date,
                    categoryId: "subscriptions",
                    accountId: accountId,
                    autoDeduct: false,
                    isPaused: status == "paused",
                    isTrial: isTrial,
                    status: status
                ))
            }
        }
        
        var newTransactions: [Transaction] = []
        if let txArray = jsonObject["transactions"] as? [[String: Any]] {
            for dict in txArray {
                guard let idStr = dict["id"] as? String,
                      let title = dict["title"] as? String,
                      let amtNum = dict["amount"] as? NSNumber,
                      let typeStr = dict["type"] as? String,
                      let catId = (dict["category"] as? String) ?? (dict["categoryId"] as? String),
                      let accId = dict["accountId"] as? String,
                      let dateStr = dict["date"] as? String else { continue }
                
                let txType = TransactionType(rawValue: typeStr) ?? .expense
                let txDate = parseDate(dateStr)
                let subId = dict["subscriptionId"] as? String
                let notes = dict["notes"] as? String
                
                newTransactions.append(Transaction(
                    id: parseUUID(idStr),
                    title: title,
                    amount: amtNum.doubleValue,
                    type: txType,
                    categoryId: catId,
                    accountId: accId,
                    toAccountId: dict["toAccountId"] as? String,
                    date: txDate,
                    notes: notes,
                    subscriptionId: subId
                ))
            }
        }
        
        withAnimation(.spring(response: 0.35)) {
            if let userName = importedUserName, !userName.isEmpty {
                self.userName = userName
            }
            if let curr = importedCurrency, !curr.isEmpty {
                self.currencyCode = curr
                self.currencySymbol = curr == "INR" ? "₹" : "$"
            }
            self.budget = newBudget
            if !newAccounts.isEmpty { self.accounts = newAccounts }
            if !newCategories.isEmpty { self.categories = newCategories }
            if !newSubscriptions.isEmpty { self.subscriptions = newSubscriptions }
            self.transactions = newTransactions
        }
        
        HapticsManager.shared.trigger(.success)
        return true
    }
}
