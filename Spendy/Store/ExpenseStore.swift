//
//  ExpenseStore.swift
//  Spendy
//
//  Observable Local-First Reactive Data Store and Persistence Engine
//

import SwiftUI
import Combine

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
    
    var currencySymbol: String = "$" {
        didSet { saveToDisk() }
    }
    
    var currencyCode: String = "USD" {
        didSet { saveToDisk() }
    }
    
    // MARK: - Initializer & Persistence
    init() {
        loadFromDisk()
    }
    
    private struct StoragePayload: Codable {
        var userName: String?
        var soundEnabled: Bool?
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
                transactions: transactions,
                accounts: accounts,
                categories: categories,
                subscriptions: subscriptions,
                budget: budget,
                currencySymbol: currencySymbol,
                currencyCode: currencyCode
            )
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storageURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to save local store: \(error.localizedDescription)")
        }
    }
    
    private func seedInitialData() {
        self.userName = "Pavan"
        self.soundEnabled = true
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
    
    func toggleSubscriptionPause(id: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                subscriptions[index].isPaused.toggle()
            }
            HapticsManager.shared.trigger(.selection)
        }
    }
    
    func deleteSubscription(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            subscriptions.removeAll(where: { $0.id == id })
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func updateMonthlyBudget(_ amount: Double) {
        budget.monthlyBudget = amount
        HapticsManager.shared.trigger(.light)
    }
    
    func updateCategoryBudget(categoryId: String, limit: Double) {
        budget.categoryBudgets[categoryId] = limit
        HapticsManager.shared.trigger(.light)
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
