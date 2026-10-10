//
//  SpendyWidgetModels.swift
//  Spendy
//
//  Shared App Group models used by the app, widgets, Siri, and Controls.
//

import Foundation
import SwiftUI

nonisolated enum SpendyAppGroup {
    static let identifier = "group.com.Spendy"
    static let snapshotKey = "spendy_widget_snapshot_data"
    static let categoriesKey = "spendy_widget_categories_data"
    static let accountsKey = "spendy_widget_accounts_data"
    static let pendingTransactionsKey = "spendy_widget_pending_transactions"
    static let pendingQuickAddKey = "spendy_widget_pending_quick_add"
    static let pendingShortcutLogKey = "spendy_widget_pending_shortcut_log"
}

enum SpendyHexColor {
    static func color(from hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func glyphColor(from hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .white
        }
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        let luminance =
            0.2126 * linear(Double(r) / 255) +
            0.7152 * linear(Double(g) / 255) +
            0.0722 * linear(Double(b) / 255)
        return luminance > 0.55 ? Color.black.opacity(0.88) : Color.white
    }
}

nonisolated enum SpendyWidgetFormat {
    static func amount(_ value: Double, symbol: String, decimals: Int = 2) -> String {
        let number = abs(value).formatted(.number.precision(.fractionLength(decimals)).grouping(.automatic))
        return "\(symbol)\(number)"
    }

    static func compactAmount(_ value: Double, symbol: String) -> String {
        let absValue = abs(value)
        if absValue >= 10_000 {
            return "\(symbol)\(absValue.formatted(.number.notation(.compactName).precision(.significantDigits(3))))"
        }
        if absValue >= 100 {
            return amount(absValue, symbol: symbol, decimals: absValue.rounded() == absValue ? 0 : 2)
        }
        return amount(absValue, symbol: symbol, decimals: 2)
    }
}

nonisolated struct WidgetDaySpending: Identifiable, Codable, Hashable, Sendable {
    var id: String { dayLabel + (isToday ? "-today" : "") }
    let dayLabel: String
    let amount: Double
    let isToday: Bool
    let dayStart: Date?

    init(dayLabel: String, amount: Double, isToday: Bool, dayStart: Date? = nil) {
        self.dayLabel = dayLabel
        self.amount = amount
        self.isToday = isToday
        self.dayStart = dayStart
    }
}

nonisolated struct WidgetTransactionItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let amount: Double
    let isExpense: Bool
    let categorySymbol: String
    let categoryColorHex: String
    let formattedTime: String
}

nonisolated struct WidgetCategorySpend: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let sfSymbol: String
    let colorHex: String
    let amount: Double
}

nonisolated struct WidgetCategoryRecord: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let sfSymbol: String
    let colorHex: String
    let isExpense: Bool
    let isHidden: Bool
    let order: Int
}

nonisolated struct WidgetAccountRecord: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let sfSymbol: String
    let colorHex: String
    let order: Int
}

nonisolated struct PendingWidgetTransaction: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let amount: Double
    let isExpense: Bool
    let isTransfer: Bool
    let categoryId: String
    let categoryName: String
    let categorySymbol: String
    let categoryColorHex: String
    let accountId: String
    let toAccountId: String?
    let notes: String?
    let date: Date
}

nonisolated struct SpendyWidgetSnapshot: Codable, Sendable {
    let currencySymbol: String
    let currencyCode: String
    let defaultAccountId: String
    let todayTotal: Double
    let todayIncome: Double
    let monthTotal: Double
    let previousMonthToDateTotal: Double?
    let remainingBudget: Double
    let budgetTotal: Double
    let budgetProgress: Double
    let budgetOverage: Double
    let budgetPeriod: String
    let budgetCycleEnd: Date?
    let topCategoryName: String
    let topCategorySymbol: String
    let topCategoryColorHex: String
    let topCategoryAmount: Double
    let weeklySpending: [WidgetDaySpending]
    let recentTransactions: [WidgetTransactionItem]
    let topCategories: [WidgetCategorySpend]
    let categorySpending: [WidgetCategorySpend]
    let daysLeft: Int
    let pacingCaption: String
    let lastUpdated: Date

    init(
        currencySymbol: String = "₹",
        currencyCode: String = "INR",
        defaultAccountId: String = "cash",
        todayTotal: Double = 0,
        todayIncome: Double = 0,
        monthTotal: Double = 0,
        previousMonthToDateTotal: Double? = nil,
        remainingBudget: Double = 0,
        budgetTotal: Double = 0,
        budgetProgress: Double = 0,
        budgetOverage: Double = 0,
        budgetPeriod: String = "monthly",
        budgetCycleEnd: Date? = nil,
        topCategoryName: String = "Groceries",
        topCategorySymbol: String = "cart.fill",
        topCategoryColorHex: String = "#34C759",
        topCategoryAmount: Double = 0,
        weeklySpending: [WidgetDaySpending] = [],
        recentTransactions: [WidgetTransactionItem] = [],
        topCategories: [WidgetCategorySpend] = [],
        categorySpending: [WidgetCategorySpend] = [],
        daysLeft: Int = 0,
        pacingCaption: String = "",
        lastUpdated: Date = Date()
    ) {
        self.currencySymbol = currencySymbol
        self.currencyCode = currencyCode
        self.defaultAccountId = defaultAccountId
        self.todayTotal = todayTotal
        self.todayIncome = todayIncome
        self.monthTotal = monthTotal
        self.previousMonthToDateTotal = previousMonthToDateTotal
        self.remainingBudget = remainingBudget
        self.budgetTotal = budgetTotal
        self.budgetProgress = budgetProgress
        self.budgetOverage = budgetOverage
        self.budgetPeriod = budgetPeriod
        self.budgetCycleEnd = budgetCycleEnd
        self.topCategoryName = topCategoryName
        self.topCategorySymbol = topCategorySymbol
        self.topCategoryColorHex = topCategoryColorHex
        self.topCategoryAmount = topCategoryAmount
        self.weeklySpending = weeklySpending
        self.recentTransactions = recentTransactions
        self.topCategories = topCategories
        self.categorySpending = categorySpending
        self.daysLeft = daysLeft
        self.pacingCaption = pacingCaption
        self.lastUpdated = lastUpdated
    }

    enum CodingKeys: String, CodingKey {
        case currencySymbol, currencyCode, defaultAccountId
        case todayTotal, todayIncome, monthTotal, previousMonthToDateTotal
        case remainingBudget, budgetTotal, budgetProgress, budgetOverage, budgetPeriod, budgetCycleEnd
        case topCategoryName, topCategorySymbol, topCategoryColorHex, topCategoryAmount
        case weeklySpending, recentTransactions, topCategories, categorySpending, daysLeft, pacingCaption, lastUpdated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol) ?? "₹"
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "INR"
        defaultAccountId = try container.decodeIfPresent(String.self, forKey: .defaultAccountId) ?? "cash"
        todayTotal = try container.decodeIfPresent(Double.self, forKey: .todayTotal) ?? 0
        todayIncome = try container.decodeIfPresent(Double.self, forKey: .todayIncome) ?? 0
        monthTotal = try container.decodeIfPresent(Double.self, forKey: .monthTotal) ?? 0
        previousMonthToDateTotal = try container.decodeIfPresent(Double.self, forKey: .previousMonthToDateTotal)
        remainingBudget = try container.decodeIfPresent(Double.self, forKey: .remainingBudget) ?? 0
        budgetTotal = try container.decodeIfPresent(Double.self, forKey: .budgetTotal) ?? 0
        budgetProgress = try container.decodeIfPresent(Double.self, forKey: .budgetProgress) ?? 0
        budgetOverage = try container.decodeIfPresent(Double.self, forKey: .budgetOverage) ?? 0
        budgetPeriod = try container.decodeIfPresent(String.self, forKey: .budgetPeriod) ?? "monthly"
        budgetCycleEnd = try container.decodeIfPresent(Date.self, forKey: .budgetCycleEnd)
        topCategoryName = try container.decodeIfPresent(String.self, forKey: .topCategoryName) ?? "Groceries"
        topCategorySymbol = try container.decodeIfPresent(String.self, forKey: .topCategorySymbol) ?? "cart.fill"
        topCategoryColorHex = try container.decodeIfPresent(String.self, forKey: .topCategoryColorHex) ?? "#34C759"
        topCategoryAmount = try container.decodeIfPresent(Double.self, forKey: .topCategoryAmount) ?? 0
        weeklySpending = try container.decodeIfPresent([WidgetDaySpending].self, forKey: .weeklySpending) ?? []
        recentTransactions = try container.decodeIfPresent([WidgetTransactionItem].self, forKey: .recentTransactions) ?? []
        topCategories = try container.decodeIfPresent([WidgetCategorySpend].self, forKey: .topCategories) ?? []
        categorySpending = try container.decodeIfPresent([WidgetCategorySpend].self, forKey: .categorySpending) ?? topCategories
        daysLeft = try container.decodeIfPresent(Int.self, forKey: .daysLeft) ?? 0
        pacingCaption = try container.decodeIfPresent(String.self, forKey: .pacingCaption) ?? ""
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }

    /// Widget timelines can outlive the last app launch. Keep day and cycle
    /// labels honest using the dates saved with the snapshot, without inventing
    /// transactions that the extension cannot read.
    func normalized(for date: Date) -> SpendyWidgetSnapshot {
        let calendar = Calendar.current
        let sameDay = calendar.isDate(lastUpdated, inSameDayAs: date)
        let sameMonth = calendar.isDate(lastUpdated, equalTo: date, toGranularity: .month)

        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let datedDays = weeklySpending.filter { $0.dayStart != nil }
        let week: [WidgetDaySpending]
        if datedDays.count == weeklySpending.count, !datedDays.isEmpty {
            week = (0..<7).reversed().compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { return nil }
                let saved = datedDays.first { point in
                    point.dayStart.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                }
                return WidgetDaySpending(
                    dayLabel: String(formatter.string(from: day).prefix(1)),
                    amount: saved?.amount ?? 0,
                    isToday: offset == 0,
                    dayStart: calendar.startOfDay(for: day)
                )
            }
        } else if sameDay {
            week = weeklySpending
        } else {
            week = (0..<7).reversed().compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { return nil }
                return WidgetDaySpending(
                    dayLabel: String(formatter.string(from: day).prefix(1)),
                    amount: 0,
                    isToday: offset == 0,
                    dayStart: calendar.startOfDay(for: day)
                )
            }
        }

        var cycleEnd = budgetCycleEnd
        var cycleChanged = false
        if budgetTotal > 0, var end = cycleEnd {
            for _ in 0..<60 {
                guard date >= end else { break }
                cycleChanged = true
                guard let next = calendar.date(
                    byAdding: budgetPeriod == "weekly" ? .weekOfYear : .month,
                    value: 1,
                    to: end
                ) else { break }
                end = next
            }
            cycleEnd = end
        }
        let room = cycleChanged ? budgetTotal : remainingBudget
        let overage = cycleChanged ? 0 : budgetOverage
        let progress = cycleChanged ? 0 : budgetProgress
        let remainingDays = cycleEnd.map {
            max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: $0)).day ?? 0)
        } ?? (sameDay ? daysLeft : max(0, daysLeft - (calendar.dateComponents([.day], from: lastUpdated, to: date).day ?? 0)))
        let dailyRoom = remainingDays > 0 ? room / Double(remainingDays) : room
        let caption = budgetTotal > 0
            ? (overage > 0
                ? "Over budget by \(SpendyWidgetFormat.compactAmount(overage, symbol: currencySymbol))"
                : "\(SpendyWidgetFormat.compactAmount(dailyRoom, symbol: currencySymbol)) per day left")
            : "No active budget"
        let categories = sameMonth ? (categorySpending.isEmpty ? topCategories : categorySpending) : []
        let top = categories.first

        return SpendyWidgetSnapshot(
            currencySymbol: currencySymbol,
            currencyCode: currencyCode,
            defaultAccountId: defaultAccountId,
            todayTotal: sameDay ? todayTotal : (week.first(where: \.isToday)?.amount ?? 0),
            todayIncome: sameDay ? todayIncome : 0,
            monthTotal: sameMonth ? monthTotal : 0,
            previousMonthToDateTotal: sameDay ? previousMonthToDateTotal : nil,
            remainingBudget: room,
            budgetTotal: budgetTotal,
            budgetProgress: progress,
            budgetOverage: overage,
            budgetPeriod: budgetPeriod,
            budgetCycleEnd: cycleEnd,
            topCategoryName: top?.name ?? "None",
            topCategorySymbol: top?.sfSymbol ?? "tag",
            topCategoryColorHex: top?.colorHex ?? "#000000",
            topCategoryAmount: top?.amount ?? 0,
            weeklySpending: week,
            recentTransactions: recentTransactions,
            topCategories: Array(categories.prefix(3)),
            categorySpending: categories,
            daysLeft: remainingDays,
            pacingCaption: caption,
            lastUpdated: lastUpdated
        )
    }

    static var empty: SpendyWidgetSnapshot {
        SpendyWidgetSnapshot(
            topCategoryName: "Spendy",
            topCategorySymbol: "cart.fill",
            topCategoryColorHex: "#34C759"
        )
    }

    static var preview: SpendyWidgetSnapshot {
        SpendyWidgetSnapshot(
            currencySymbol: "₹",
            currencyCode: "INR",
            defaultAccountId: "cash",
            todayTotal: 34,
            todayIncome: 0,
            monthTotal: 845,
            previousMonthToDateTotal: 720,
            remainingBudget: 655,
            budgetTotal: 1500,
            budgetProgress: 0.56,
            topCategoryName: "Groceries",
            topCategorySymbol: "cart.fill",
            topCategoryColorHex: "#34C759",
            topCategoryAmount: 312,
            weeklySpending: [
                WidgetDaySpending(dayLabel: "M", amount: 24.50, isToday: false),
                WidgetDaySpending(dayLabel: "T", amount: 65.00, isToday: false),
                WidgetDaySpending(dayLabel: "W", amount: 18.20, isToday: false),
                WidgetDaySpending(dayLabel: "T", amount: 82.00, isToday: false),
                WidgetDaySpending(dayLabel: "F", amount: 45.00, isToday: false),
                WidgetDaySpending(dayLabel: "S", amount: 92.50, isToday: false),
                WidgetDaySpending(dayLabel: "S", amount: 34.00, isToday: true)
            ],
            recentTransactions: [
                WidgetTransactionItem(
                    id: "1",
                    title: "Coffee",
                    amount: 5.50,
                    isExpense: true,
                    categorySymbol: "cup.and.saucer.fill",
                    categoryColorHex: "#A2845E",
                    formattedTime: "10:30 AM"
                ),
                WidgetTransactionItem(
                    id: "2",
                    title: "Groceries",
                    amount: 28.50,
                    isExpense: true,
                    categorySymbol: "cart.fill",
                    categoryColorHex: "#34C759",
                    formattedTime: "12:15 PM"
                ),
                WidgetTransactionItem(
                    id: "3",
                    title: "Salary",
                    amount: 2400,
                    isExpense: false,
                    categorySymbol: "banknote.fill",
                    categoryColorHex: "#34C759",
                    formattedTime: "9:00 AM"
                )
            ],
            topCategories: [
                WidgetCategorySpend(id: "groceries", name: "Groceries", sfSymbol: "cart.fill", colorHex: "#34C759", amount: 312),
                WidgetCategorySpend(id: "coffee", name: "Coffee & Cafés", sfSymbol: "cup.and.saucer.fill", colorHex: "#A2845E", amount: 148),
                WidgetCategorySpend(id: "fuel", name: "Fuel", sfSymbol: "fuelpump.fill", colorHex: "#FF9500", amount: 96)
            ],
            categorySpending: [
                WidgetCategorySpend(id: "groceries", name: "Groceries", sfSymbol: "cart.fill", colorHex: "#34C759", amount: 312),
                WidgetCategorySpend(id: "coffee", name: "Coffee & Cafés", sfSymbol: "cup.and.saucer.fill", colorHex: "#A2845E", amount: 148),
                WidgetCategorySpend(id: "fuel", name: "Fuel", sfSymbol: "fuelpump.fill", colorHex: "#FF9500", amount: 96)
            ],
            daysLeft: 14,
            pacingCaption: "₹47 per day left",
            lastUpdated: Date()
        )
    }

    static let fallbackCategories: [WidgetCategoryRecord] = [
        WidgetCategoryRecord(id: "groceries", name: "Groceries", sfSymbol: "cart.fill", colorHex: "#34C759", isExpense: true, isHidden: false, order: 0),
        WidgetCategoryRecord(id: "restaurants", name: "Restaurants", sfSymbol: "fork.knife", colorHex: "#FF9F0A", isExpense: true, isHidden: false, order: 1),
        WidgetCategoryRecord(id: "coffee", name: "Coffee & Cafés", sfSymbol: "cup.and.saucer.fill", colorHex: "#A2845E", isExpense: true, isHidden: false, order: 2),
        WidgetCategoryRecord(id: "fuel", name: "Fuel", sfSymbol: "fuelpump.fill", colorHex: "#FF9500", isExpense: true, isHidden: false, order: 3),
        WidgetCategoryRecord(id: "shopping", name: "Shopping", sfSymbol: "bag.fill", colorHex: "#5856D6", isExpense: true, isHidden: false, order: 4),
        WidgetCategoryRecord(id: "transport", name: "Taxi & Ride-hailing", sfSymbol: "car.fill", colorHex: "#FFCC00", isExpense: true, isHidden: false, order: 5),
        WidgetCategoryRecord(id: "health", name: "Health & Fitness", sfSymbol: "heart.fill", colorHex: "#FF2D55", isExpense: true, isHidden: false, order: 6),
        WidgetCategoryRecord(id: "entertainment", name: "Entertainment", sfSymbol: "popcorn.fill", colorHex: "#BF5AF2", isExpense: true, isHidden: false, order: 7),
        WidgetCategoryRecord(id: "paycheck", name: "Salary / Paycheck", sfSymbol: "banknote.fill", colorHex: "#34C759", isExpense: false, isHidden: false, order: 0),
        WidgetCategoryRecord(id: "freelance", name: "Freelance", sfSymbol: "laptopcomputer", colorHex: "#007AFF", isExpense: false, isHidden: false, order: 1),
        WidgetCategoryRecord(id: "bonus", name: "Bonus", sfSymbol: "sparkles", colorHex: "#FFD60A", isExpense: false, isHidden: false, order: 2)
    ]

    static let fallbackAccounts: [WidgetAccountRecord] = [
        WidgetAccountRecord(id: "cash", name: "Cash", sfSymbol: "banknote.fill", colorHex: "#34C759", order: 0),
        WidgetAccountRecord(id: "bank", name: "Bank Account", sfSymbol: "building.columns.fill", colorHex: "#007AFF", order: 1)
    ]
}

nonisolated final class WidgetDataManager: @unchecked Sendable {
    static let shared = WidgetDataManager()

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let containerURL: URL?

    private init() {
        defaults = UserDefaults(suiteName: SpendyAppGroup.identifier) ?? .standard
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SpendyAppGroup.identifier
        )
    }

    func saveSnapshot(_ snapshot: SpendyWidgetSnapshot) {
        persist(snapshot, key: SpendyAppGroup.snapshotKey, filename: "widget_snapshot.json")
    }

    func loadSnapshot(asOf date: Date = Date()) -> SpendyWidgetSnapshot {
        if let snapshot: SpendyWidgetSnapshot = load(key: SpendyAppGroup.snapshotKey, filename: "widget_snapshot.json") {
            return snapshot.normalized(for: date)
        }
        return SpendyWidgetSnapshot.empty.normalized(for: date)
    }

    func saveCategories(_ categories: [WidgetCategoryRecord]) {
        persist(categories, key: SpendyAppGroup.categoriesKey, filename: "widget_categories.json")
    }

    func loadCategories() -> [WidgetCategoryRecord] {
        if let categories: [WidgetCategoryRecord] = load(key: SpendyAppGroup.categoriesKey, filename: "widget_categories.json"),
           !categories.isEmpty {
            return categories
        }
        return SpendyWidgetSnapshot.fallbackCategories
    }

    func saveAccounts(_ accounts: [WidgetAccountRecord]) {
        persist(accounts, key: SpendyAppGroup.accountsKey, filename: "widget_accounts.json")
    }

    func loadAccounts() -> [WidgetAccountRecord] {
        if let accounts: [WidgetAccountRecord] = load(key: SpendyAppGroup.accountsKey, filename: "widget_accounts.json"),
           !accounts.isEmpty {
            return accounts
        }
        return SpendyWidgetSnapshot.fallbackAccounts
    }

    private func persist<T: Encodable>(_ value: T, key: String, filename: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
        if let url = containerURL?.appendingPathComponent(filename) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func load<T: Decodable>(key: String, filename: String) -> T? {
        if let data = defaults.data(forKey: key), let value = try? decoder.decode(T.self, from: data) {
            return value
        }
        if let url = containerURL?.appendingPathComponent(filename),
           let data = try? Data(contentsOf: url),
           let value = try? decoder.decode(T.self, from: data) {
            return value
        }
        return nil
    }

    func enqueuePendingTransaction(_ item: PendingWidgetTransaction) {
        var items = loadPendingTransactions()
        items.append(item)
        savePendingTransactions(items)
    }

    func loadPendingTransactions() -> [PendingWidgetTransaction] {
        guard let data = defaults.data(forKey: SpendyAppGroup.pendingTransactionsKey),
              let items = try? decoder.decode([PendingWidgetTransaction].self, from: data) else {
            return []
        }
        return items
    }

    /// Acknowledge only records already committed by the app; keep newer queued items.
    func acknowledgePendingTransactions(ids: Set<String>) {
        savePendingTransactions(loadPendingTransactions().filter { !ids.contains($0.id) })
    }

    func consumePendingTransactions() -> [PendingWidgetTransaction] {
        let items = loadPendingTransactions()
        defaults.removeObject(forKey: SpendyAppGroup.pendingTransactionsKey)
        return items
    }

    func setPendingQuickAdd() {
        defaults.set(true, forKey: SpendyAppGroup.pendingQuickAddKey)
    }

    func consumePendingQuickAdd() -> Bool {
        let pending = defaults.bool(forKey: SpendyAppGroup.pendingQuickAddKey)
        defaults.set(false, forKey: SpendyAppGroup.pendingQuickAddKey)
        return pending
    }

    func setPendingShortcutLog() {
        defaults.set(true, forKey: SpendyAppGroup.pendingShortcutLogKey)
    }

    func consumePendingShortcutLog() -> Bool {
        let pending = defaults.bool(forKey: SpendyAppGroup.pendingShortcutLogKey)
        defaults.set(false, forKey: SpendyAppGroup.pendingShortcutLogKey)
        return pending
    }

    func recordLoggedTransaction(
        amount: Double,
        isExpense: Bool,
        categoryId: String,
        categoryName: String,
        categorySymbol: String,
        categoryColorHex: String,
        note: String?
    ) {
        let snapshot = loadSnapshot()
        let item = PendingWidgetTransaction(
            id: UUID().uuidString,
            title: (note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                ? note!.trimmingCharacters(in: .whitespacesAndNewlines)
                : categoryName,
            amount: abs(amount),
            isExpense: isExpense,
            isTransfer: false,
            categoryId: categoryId,
            categoryName: categoryName,
            categorySymbol: categorySymbol,
            categoryColorHex: categoryColorHex,
            accountId: snapshot.defaultAccountId,
            toAccountId: nil,
            notes: note,
            date: Date()
        )
        enqueuePendingTransaction(item)
        saveSnapshot(applying: item, to: snapshot)
    }

    func recordTransfer(
        amount: Double,
        fromAccountId: String,
        fromAccountName: String,
        toAccountId: String,
        toAccountName: String,
        fromSymbol: String,
        fromColorHex: String,
        note: String?
    ) {
        let snapshot = loadSnapshot()
        let title = (note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? note!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "\(fromAccountName) → \(toAccountName)"
        let item = PendingWidgetTransaction(
            id: UUID().uuidString,
            title: title,
            amount: abs(amount),
            isExpense: false,
            isTransfer: true,
            categoryId: "transfer",
            categoryName: "Transfer",
            categorySymbol: fromSymbol,
            categoryColorHex: fromColorHex,
            accountId: fromAccountId,
            toAccountId: toAccountId,
            notes: note,
            date: Date()
        )
        enqueuePendingTransaction(item)
        saveSnapshot(applying: item, to: snapshot)
    }

    private func savePendingTransactions(_ items: [PendingWidgetTransaction]) {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: SpendyAppGroup.pendingTransactionsKey)
        }
    }

    private func saveSnapshot(applying item: PendingWidgetTransaction, to snapshot: SpendyWidgetSnapshot) {
        var weekly = snapshot.weeklySpending
        if item.isExpense, let todayIndex = weekly.lastIndex(where: { $0.isToday }) {
            let today = weekly[todayIndex]
            weekly[todayIndex] = WidgetDaySpending(
                dayLabel: today.dayLabel,
                amount: today.amount + item.amount,
                isToday: true,
                dayStart: today.dayStart
            )
        }

        let recent = [
            WidgetTransactionItem(
                id: item.id,
                title: item.title,
                amount: item.amount,
                isExpense: item.isExpense,
                categorySymbol: item.categorySymbol,
                categoryColorHex: item.categoryColorHex,
                formattedTime: DateFormatter.localizedString(from: item.date, dateStyle: .none, timeStyle: .short)
            )
        ] + snapshot.recentTransactions.prefix(2)

        let expense = item.isExpense ? item.amount : 0
        let todayTotal = snapshot.todayTotal + expense
        let todayIncome = snapshot.todayIncome + (!item.isExpense && !item.isTransfer ? item.amount : 0)
        let monthTotal = snapshot.monthTotal + expense
        let previousBudgetSpent = snapshot.budgetTotal - snapshot.remainingBudget + snapshot.budgetOverage
        let budgetSpent = snapshot.budgetTotal > 0 ? previousBudgetSpent + expense : 0
        let remaining = snapshot.budgetTotal > 0 ? max(0, snapshot.budgetTotal - budgetSpent) : 0
        let overage = snapshot.budgetTotal > 0 ? max(0, budgetSpent - snapshot.budgetTotal) : 0
        let progress = snapshot.budgetTotal > 0 ? min(1, max(0, budgetSpent / snapshot.budgetTotal)) : 0
        var categorySpending = snapshot.categorySpending
        if item.isExpense {
            if let index = categorySpending.firstIndex(where: { $0.id == item.categoryId }) {
                let old = categorySpending[index]
                categorySpending[index] = WidgetCategorySpend(
                    id: old.id, name: old.name, sfSymbol: old.sfSymbol,
                    colorHex: old.colorHex, amount: old.amount + item.amount
                )
            } else {
                categorySpending.append(WidgetCategorySpend(
                    id: item.categoryId, name: item.categoryName, sfSymbol: item.categorySymbol,
                    colorHex: item.categoryColorHex, amount: item.amount
                ))
            }
            categorySpending.sort { $0.amount > $1.amount }
        }
        let topCategory = categorySpending.first
        let dailyPace = snapshot.daysLeft > 0 ? remaining / Double(snapshot.daysLeft) : remaining
        let pacingCaption = snapshot.budgetTotal > 0
            ? (overage > 0
                ? "Over budget by \(SpendyWidgetFormat.compactAmount(overage, symbol: snapshot.currencySymbol))"
                : "\(SpendyWidgetFormat.compactAmount(dailyPace, symbol: snapshot.currencySymbol)) per day left")
            : "No active budget"

        saveSnapshot(
            SpendyWidgetSnapshot(
                currencySymbol: snapshot.currencySymbol,
                currencyCode: snapshot.currencyCode,
                defaultAccountId: snapshot.defaultAccountId,
                todayTotal: todayTotal,
                todayIncome: todayIncome,
                monthTotal: monthTotal,
                previousMonthToDateTotal: snapshot.previousMonthToDateTotal,
                remainingBudget: remaining,
                budgetTotal: snapshot.budgetTotal,
                budgetProgress: progress,
                budgetOverage: overage,
                budgetPeriod: snapshot.budgetPeriod,
                budgetCycleEnd: snapshot.budgetCycleEnd,
                topCategoryName: topCategory?.name ?? "None",
                topCategorySymbol: topCategory?.sfSymbol ?? "tag",
                topCategoryColorHex: topCategory?.colorHex ?? "#000000",
                topCategoryAmount: topCategory?.amount ?? 0,
                weeklySpending: weekly,
                recentTransactions: Array(recent),
                topCategories: Array(categorySpending.prefix(3)),
                categorySpending: categorySpending,
                daysLeft: snapshot.daysLeft,
                pacingCaption: pacingCaption,
                lastUpdated: Date()
            )
        )
    }
}
