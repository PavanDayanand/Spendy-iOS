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

enum DashboardSectionId: String, Codable, CaseIterable, Identifiable {
    case spendingChart = "spending_chart"
    case budget = "budget"
    case spendingByCategory = "spending_by_category"
    case upcoming = "upcoming"
    case accounts = "accounts"
    case recentTransactions = "recent_transactions"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .spendingChart: return "Spending chart"
        case .budget: return "Budget"
        case .spendingByCategory: return "Spending by category"
        case .upcoming: return "Upcoming"
        case .accounts: return "Accounts"
        case .recentTransactions: return "Recent transactions"
        }
    }
    
    var isAlwaysVisible: Bool {
        self == .recentTransactions
    }
}

@Observable
@MainActor
final class ExpenseStore {
    static let shared: ExpenseStore = {
        #if DEBUG
        // UI tests get their own temporary ledger, including a reproducible recovery fixture.
        if let mode = ProcessInfo.processInfo.environment["SPENDY_UI_TEST_MODE"] {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ui-test-\(UUID().uuidString).json")
            let fixture = ExpenseStore(storageURL: url, startsServices: false)
            fixture.hasCompletedOnboarding = true
            fixture.transactions = [Transaction(title: "Readiness expense", amount: 25, categoryId: "groceries", accountId: "cash")]
            if mode == "analytics" {
                fixture.transactions = Array(fixture.categories.filter { $0.type == .expense }.prefix(10)).enumerated().map { index, category in
                    Transaction(title: "Analytics expense \(index)", amount: Double(60 - index * 5), categoryId: category.id, accountId: "cash")
                }
            }
            if mode == "charts" {
                let calendar = Calendar.current
                let now = Date()
                let start = calendar.dateInterval(of: .month, for: now)!.start
                fixture.transactions = (-5...0).flatMap { offset -> [Transaction] in
                    let month = calendar.date(byAdding: .month, value: offset, to: start)!
                    let total = [1800.0, 1100, 2100, 1350, 1500, 1200][offset + 5]
                    return [
                        Transaction(title: "Chart groceries", amount: total * 0.5, categoryId: "groceries", accountId: "cash", date: month),
                        Transaction(title: "Chart dining", amount: total * 0.3, categoryId: "food", accountId: "bank", date: month),
                        Transaction(title: "Chart coffee", amount: total * 0.2, categoryId: "coffee", accountId: "cash", date: month)
                    ]
                }
                fixture.transactions += [
                    Transaction(title: "Future chart expense", amount: 9999, categoryId: "groceries", accountId: "cash", date: now.addingTimeInterval(86400)),
                    Transaction(title: "Chart salary", amount: 5000, type: .income, categoryId: "salary", accountId: "cash", date: now)
                ]
            }
            if mode == "home-attention" || mode == "home-attention-single" || mode == "home-stability" {
                let now = Date()
                fixture.subscriptions = [
                    Subscription(name: "Today Music", amount: 99, nextBillingDate: now),
                    Subscription(name: "Today Storage", amount: 49, nextBillingDate: now),
                    Subscription(name: "Paused Today", amount: 999, nextBillingDate: now, isPaused: true)
                ]
                if mode == "home-attention-single" { fixture.subscriptions = Array(fixture.subscriptions.prefix(1)) }
                fixture.budget = Budget(amount: 100, isActive: mode != "home-attention-single")
                fixture.transactions = [Transaction(title: "Budget expense", amount: 125, categoryId: "groceries", accountId: "cash", date: now)]
            }
            if mode == "home-stability" {
                fixture.transactions += [
                    Transaction(title: "Second recent expense", amount: 20, categoryId: "groceries", accountId: "cash"),
                    Transaction(title: "Third recent expense", amount: 30, categoryId: "groceries", accountId: "cash")
                ]
            }
            if mode == "insights-disabled" { fixture.insightsEnabled = false }
            if mode == "subscription-detail" {
                fixture.subscriptions = [Subscription(name: "Readiness Music", amount: 12, nextBillingDate: Date().addingTimeInterval(86400))]
            }
            if mode == "insights" {
                let current = (0..<3).map { index in
                    Transaction(title: "Pager expense \(index)", amount: 50, categoryId: "groceries", accountId: "cash",
                        date: Calendar.current.date(byAdding: .day, value: -(index + 2), to: Date())!)
                }
                fixture.transactions = current + current.map { tx in
                    Transaction(title: "Previous expense", amount: 100, categoryId: "groceries", accountId: "cash",
                        date: Calendar.current.date(byAdding: .month, value: -1, to: tx.date)!)
                }
                fixture.budget = Budget(amount: 100, isActive: true)
            }
            if ProcessInfo.processInfo.environment["SPENDY_UI_TEST_APPEARANCE"] == "light" {
                fixture.appearanceMode = .light
            }
            fixture.flushPendingSave()
            fixture.flushPendingSave()
            if mode == "recovery" { try? Data("unreadable UI test fixture".utf8).write(to: url) }
            return ExpenseStore(storageURL: url, startsServices: false)
        }
        #endif
        return ExpenseStore()
    }()

    var systemIntegrationsEnabled: Bool { startsServices && loadError == nil }
    
    // MARK: - App State
    
    @ObservationIgnored private var _saveTask: Task<Void, Never>?
    @ObservationIgnored private var _cachedBalances: [String: Double]?
    @ObservationIgnored private var _cachedCategoryMap: [String: Category]?
    @ObservationIgnored private var _cachedAccountMap: [String: Account]?
    
    @ObservationIgnored private let storageURL: URL
    @ObservationIgnored private let writer = LocalStoreWriter()
    @ObservationIgnored private let startsServices: Bool
    @ObservationIgnored private var canSave = false
    @ObservationIgnored private var saveRevision = 0
    var loadError: String?
    var persistenceError: String?

    var hasRecoveryBackup: Bool {
        FileManager.default.fileExists(atPath: storageURL.appendingPathExtension("backup").path)
    }

    private func scheduleSave() {
        guard canSave else { return }
        _saveTask?.cancel()
        _saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self.saveToDisk()
        }
    }

    var userName: String = "" {
        didSet { scheduleSave() }
    }
    
    var hapticsEnabled: Bool = true {
        didSet {
            HapticsManager.shared.isEnabled = hapticsEnabled
            scheduleSave()
        }
    }
    
    var profileImageData: Data? = nil {
        didSet { scheduleSave() }
    }
    
    var profileIconSymbol: String? = nil {
        didSet { scheduleSave() }
    }
    
    var profileColorHex: String? = nil {
        didSet { scheduleSave() }
    }
    
    var soundEnabled: Bool = true {
        didSet {
            SoundManager.shared.isEnabled = soundEnabled
            scheduleSave()
        }
    }
    
    var hasCompletedOnboarding: Bool = false {
        didSet { scheduleSave() }
    }
    
    var insightsEnabled = true { didSet { scheduleSave() } }
    var weeklySummaryEnabled = false { didSet { scheduleSave() } }
    var loggingRemindersEnabled = false { didSet { scheduleSave() } }
    var budgetAlertsEnabled = false { didSet { scheduleSave() } }

    var notificationsEnabled: Bool = true {
        didSet { scheduleSave() }
    }
    
    var transactions: [Transaction] = [] {
        didSet {
            _cachedBalances = nil
            scheduleSave()
        }
    }
    
    var accounts: [Account] = [] {
        didSet {
            _cachedBalances = nil
            _cachedAccountMap = nil
            scheduleSave()
        }
    }
    
    var categories: [Category] = [] {
        didSet {
            _cachedCategoryMap = nil
            scheduleSave()
        }
    }
    
    var customFolders: [Folder] = [] {
        didSet { scheduleSave() }
    }
    
    var subscriptions: [Subscription] = [] {
        didSet { scheduleSave() }
    }
    
    var budget: Budget = Budget() {
        didSet { scheduleSave() }
    }
    
    private static func displayCurrencySymbol(_ symbol: String, code: String) -> String {
        code.uppercased() == "AOA" && symbol.uppercased() == "AOA" ? "Kz" : symbol
    }

    var currencySymbol: String = "₹" {
        didSet { scheduleSave() }
    }
    
    var currencyCode: String = "INR" {
        didSet { scheduleSave() }
    }
    
    // The API returns units of each currency per USD. Never use sample rates as live data.
    var ratesToUSD: [String: Double] = ["USD": 1.0] {
        didSet { scheduleSave() }
    }
    
    var ratesLastUpdated: Date? = nil {
        didSet { scheduleSave() }
    }

    var ratesNextUpdate: Date? = nil {
        didSet { scheduleSave() }
    }

    var isRefreshingRates = false
    var ratesError: String? = nil
    
    var ratesLastUpdatedFormatted: String {
        guard let date = ratesLastUpdated else { return "Not updated yet" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var appearanceMode: AppearanceMode = .dark {
        didSet { scheduleSave() }
    }
    
    var isMonoIconMode: Bool = true {
        didSet {
            SpendyColors.isMonoMode = isMonoIconMode
            scheduleSave()
        }
    }
    
    // MARK: - Dashboard Section Visibility & Ordering Controls
    var dashboardSectionOrder: [DashboardSectionId] = [
        .spendingChart,
        .budget,
        .spendingByCategory,
        .upcoming,
        .accounts,
        .recentTransactions
    ] {
        didSet { scheduleSave() }
    }
    
    var dashboardHiddenSections: [String] = [] {
        didSet { scheduleSave() }
    }
    
    func isSectionVisible(_ section: DashboardSectionId) -> Bool {
        if section.isAlwaysVisible { return true }
        return !dashboardHiddenSections.contains(section.id)
    }
    
    func setSectionVisible(_ section: DashboardSectionId, isVisible: Bool) {
        if section.isAlwaysVisible { return }
        if isVisible {
            dashboardHiddenSections.removeAll { $0 == section.id }
        } else {
            if !dashboardHiddenSections.contains(section.id) {
                dashboardHiddenSections.append(section.id)
            }
        }
    }
    
    func resetDashboardConfigToDefault() {
        dashboardSectionOrder = [
            .spendingChart,
            .budget,
            .spendingByCategory,
            .upcoming,
            .accounts,
            .recentTransactions
        ]
        dashboardHiddenSections = []
    }
    
    var showHomeSpendBarChart: Bool {
        get { isSectionVisible(.spendingChart) }
        set { setSectionVisible(.spendingChart, isVisible: newValue) }
    }
    var showHomeBudgetCard: Bool {
        get { isSectionVisible(.budget) }
        set { setSectionVisible(.budget, isVisible: newValue) }
    }
    var showHomeSmartInsights: Bool {
        get { isSectionVisible(.spendingByCategory) }
        set { setSectionVisible(.spendingByCategory, isVisible: newValue) }
    }
    var showHomeAccountsCard: Bool {
        get { isSectionVisible(.accounts) }
        set { setSectionVisible(.accounts, isVisible: newValue) }
    }
    
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return nil
        }
    }
    
    var isGradientBackgroundEnabled: Bool = true {
        didSet { scheduleSave() }
    }
    
    var topGradientHue: Double = 0.60 {
        didSet {
            updateGradientHexFromHSB()
            scheduleSave()
        }
    }
    
    var topGradientBrightness: Double = 0.85 {
        didSet {
            updateGradientHexFromHSB()
            scheduleSave()
        }
    }
    
    var topGradientColorHex: String = "#007AFF" {
        didSet { scheduleSave() }
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
    
    // MARK: - JSON Coders with Multi-Format Date Support
    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
            let iso = Date.ISO8601FormatStyle()
            let dateOnly = Date.ISO8601FormatStyle().year().month().day()

            let container = try decoder.singleValueContainer()
            if let dateStr = try? container.decode(String.self) {
                if let date = try? fractional.parse(dateStr) { return date }
                if let date = try? iso.parse(dateStr) { return date }
                if let date = try? dateOnly.parse(dateStr) { return date }
            }
            if let ms = try? container.decode(Double.self) {
                if ms > 10_000_000_000 { // Millisecond timestamp
                    return Date(timeIntervalSince1970: ms / 1000.0)
                } else {
                    return Date(timeIntervalSince1970: ms)
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date in backup")
        }
        return decoder
    }
    
    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    // MARK: - Initializer & Persistence
    init(storageURL: URL? = nil, startsServices: Bool = true) {
        self.storageURL = storageURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("spendy_local_store.json")
        self.startsServices = startsServices
        loadFromDisk()
        if startsServices && loadError == nil {
            Task { await refreshExchangeRates() }
            HapticsManager.shared.isEnabled = hapticsEnabled
        }
    }
    
    private struct StoragePayload: Codable, Sendable {
        var userName: String?
        var hapticsEnabled: Bool?
        var profileImageData: Data?
        var profileIconSymbol: String?
        var profileColorHex: String?
        var soundEnabled: Bool?
        var insightsEnabled: Bool?
        var weeklySummaryEnabled: Bool?
        var loggingRemindersEnabled: Bool?
        var budgetAlertsEnabled: Bool?
        var notificationsEnabled: Bool?
        var appearanceMode: AppearanceMode?
        var isMonoIconMode: Bool?
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
        var showHomeSpendBarChart: Bool?
        var showHomeBudgetCard: Bool?
        var showHomeSmartInsights: Bool?
        var showHomeAccountsCard: Bool?
        var dashboardSectionOrder: [String]?
        var dashboardHiddenSections: [String]?
        var customFolders: [Folder]?
        var ratesToUSD: [String: Double]?
        var ratesLastUpdated: Date?
        var ratesNextUpdate: Date?
        var hasCompletedOnboarding: Bool?
        // Read only for migrating profile images saved by older versions.
        var selectedSticker: String?
    }
    
    func loadFromDisk() {
        _saveTask?.cancel()
        canSave = false
        loadError = nil
        if FileManager.default.fileExists(atPath: storageURL.path) {
            do {
                let data = try Data(contentsOf: storageURL)
                let payload = try ExpenseStore.jsonDecoder.decode(StoragePayload.self, from: data)
                try Self.validate(payload)
                self.userName = payload.userName ?? ""
                self.hapticsEnabled = payload.hapticsEnabled ?? true
                self.profileImageData = payload.profileImageData
                self.profileIconSymbol = payload.profileIconSymbol
                self.profileColorHex = payload.profileColorHex
                self.soundEnabled = payload.soundEnabled ?? true
                self.insightsEnabled = payload.insightsEnabled ?? true
                self.weeklySummaryEnabled = payload.weeklySummaryEnabled ?? false
                self.loggingRemindersEnabled = payload.loggingRemindersEnabled ?? false
                self.budgetAlertsEnabled = payload.budgetAlertsEnabled ?? false
                self.notificationsEnabled = payload.notificationsEnabled ?? true
                self.appearanceMode = payload.appearanceMode ?? .dark
                self.isMonoIconMode = true
                SpendyColors.isMonoMode = self.isMonoIconMode
                self.topGradientColorHex = payload.topGradientColorHex ?? "#007AFF"
                self.isGradientBackgroundEnabled = payload.isGradientBackgroundEnabled ?? true
                self.topGradientHue = payload.topGradientHue ?? 0.60
                self.topGradientBrightness = payload.topGradientBrightness ?? 0.85
                if let orderRaw = payload.dashboardSectionOrder {
                    let decodedOrder = orderRaw.compactMap { DashboardSectionId(rawValue: $0) }
                    var fullOrder = decodedOrder
                    for section in DashboardSectionId.allCases {
                        if !fullOrder.contains(section) {
                            fullOrder.append(section)
                        }
                    }
                    self.dashboardSectionOrder = fullOrder
                } else {
                    self.dashboardSectionOrder = [
                        .spendingChart,
                        .budget,
                        .spendingByCategory,
                        .upcoming,
                        .accounts,
                        .recentTransactions
                    ]
                }
                self.dashboardHiddenSections = payload.dashboardHiddenSections ?? []
                self.transactions = payload.transactions
                self.accounts = payload.accounts
                self.categories = payload.categories
                self.subscriptions = payload.subscriptions
                self.budget = payload.budget
                self.currencySymbol = Self.displayCurrencySymbol(payload.currencySymbol, code: payload.currencyCode)
                self.currencyCode = payload.currencyCode
                self.customFolders = payload.customFolders ?? []
                self.ratesLastUpdated = payload.ratesLastUpdated
                self.ratesNextUpdate = payload.ratesNextUpdate
                self.ratesToUSD = payload.ratesLastUpdated == nil ? ["USD": 1.0] : (payload.ratesToUSD ?? ["USD": 1.0])
                self.hasCompletedOnboarding = payload.hasCompletedOnboarding ?? false
                // Earlier versions copied the chosen sticker into the profile photo.
                // Remove only that exact generated image; preserve real profile photos.
                if let selectedSticker = payload.selectedSticker,
                   (1...8).contains(where: { selectedSticker == "Sticker\($0)" }),
                   let stickerData = UIImage(named: selectedSticker)?.pngData(),
                   profileImageData == stickerData {
                    self.profileImageData = nil
                }
                // Migration: Ensure seeded accounts are typed
                for i in 0..<self.accounts.count {
                    if self.accounts[i].id == "cash" {
                        self.accounts[i].type = .cash
                    }
                }
                // Migration: Ensure default category icons match design
                for i in 0..<self.categories.count {
                    if self.categories[i].id == "groceries" && (self.categories[i].sfSymbol == "basket.fill" || self.categories[i].colorHex == "#03DBFF") {
                        self.categories[i].sfSymbol = SFIcons.groceries
                        self.categories[i].colorHex = "#34C759"
                    }
                }
                canSave = true
                if startsServices { WidgetDataManager.shared.publish(from: self) }
                return
            } catch {
                loadError = "Spendy couldn’t read your saved data. Your original file is safe. Try again, or restore a backup."
                return
            }
        }
        
        // Seed initial default user state for first run
        canSave = true
        seedInitialData()
        if startsServices { WidgetDataManager.shared.publish(from: self) }
    }

    func restoreRecoveryBackup() {
        guard loadError != nil else { return }
        do {
            let backup = try Data(contentsOf: storageURL.appendingPathExtension("backup"))
            restoreRecoveryData(backup)
        } catch {
            loadError = "The backup couldn’t be opened. Try importing another backup. Your original files are safe."
        }
    }

    func restoreRecoveryData(_ backup: Data) {
        guard loadError != nil else { return }
        do {
            let payload = try Self.jsonDecoder.decode(StoragePayload.self, from: backup)
            try Self.validate(payload)
            if FileManager.default.fileExists(atPath: storageURL.path) {
                try FileManager.default.copyItem(at: storageURL, to: storageURL.appendingPathExtension("unreadable-\(UUID().uuidString)"))
            }
            try backup.write(to: storageURL, options: .atomic)
            loadFromDisk()
        } catch {
            loadError = "This backup couldn’t be restored. Choose a valid Spendy JSON backup. Your original files are safe."
        }
    }

    /// Drain queued writes and commit the latest snapshot before the app is suspended.
    func flushPendingSave() {
        guard canSave else { return }
        _saveTask?.cancel()
        saveToDisk(flush: true)
    }

    private func saveToDisk(flush: Bool = false, clearRecovery: Bool = false) {
        guard canSave else { return }
        if startsServices { WidgetDataManager.shared.publish(from: self) }
        let payload = StoragePayload(
            userName: userName,
            hapticsEnabled: hapticsEnabled,
            profileImageData: profileImageData,
            profileIconSymbol: profileIconSymbol,
            profileColorHex: profileColorHex,
            soundEnabled: soundEnabled,
            insightsEnabled: insightsEnabled,
            weeklySummaryEnabled: weeklySummaryEnabled,
            loggingRemindersEnabled: loggingRemindersEnabled,
            budgetAlertsEnabled: budgetAlertsEnabled,
            notificationsEnabled: notificationsEnabled,
            appearanceMode: appearanceMode,
            isMonoIconMode: isMonoIconMode,
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
            showHomeSpendBarChart: isSectionVisible(.spendingChart),
            showHomeBudgetCard: isSectionVisible(.budget),
            showHomeSmartInsights: isSectionVisible(.spendingByCategory),
            showHomeAccountsCard: isSectionVisible(.accounts),
            dashboardSectionOrder: dashboardSectionOrder.map { $0.rawValue },
            dashboardHiddenSections: dashboardHiddenSections,
            customFolders: customFolders,
            ratesToUSD: ratesToUSD,
            ratesLastUpdated: ratesLastUpdated,
            ratesNextUpdate: ratesNextUpdate,
            hasCompletedOnboarding: hasCompletedOnboarding,
            selectedSticker: nil
        )
        saveRevision += 1
        let revision = saveRevision
        do {
            let data = try Self.jsonEncoder.encode(payload)
            if flush {
                persistenceError = writer.flush(data, to: storageURL, clearRecovery: clearRecovery)
            } else {
                writer.enqueue(data, to: storageURL) { [self] error in
                    Task { @MainActor in
                        guard self.saveRevision == revision else { return }
                        self.persistenceError = error
                    }
                }
            }
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private static func validate(_ payload: StoragePayload) throws {
        let accountIDs = Set(payload.accounts.map(\.id))
        let valid = accountIDs.count == payload.accounts.count
            && Set(payload.categories.map(\.id)).count == payload.categories.count
            && Set(payload.transactions.map(\.id)).count == payload.transactions.count
            && Set(payload.subscriptions.map(\.id)).count == payload.subscriptions.count
            && payload.accounts.allSatisfy { $0.openingBalance.isFinite }
            && payload.budget.amount.isFinite && payload.budget.amount >= 0
            && payload.budget.categoryBudgets.values.allSatisfy { $0.isFinite && $0 >= 0 }
            && payload.transactions.allSatisfy {
                $0.amount.isFinite && $0.amount >= 0 && accountIDs.contains($0.accountId)
                && ($0.type != .transfer || accountIDs.contains($0.toAccountId ?? ""))
            }
            && payload.subscriptions.allSatisfy { $0.amount.isFinite && $0.amount >= 0 && accountIDs.contains($0.accountId) }
        guard valid else {
            throw NSError(domain: "Spendy.Backup", code: 1, userInfo: [NSLocalizedDescriptionKey: "The backup contains duplicate IDs, invalid amounts, or missing accounts."])
        }
    }
    
    private func seedInitialData() {
        self.userName = ""
        self.soundEnabled = true
        self.insightsEnabled = true
        self.weeklySummaryEnabled = false
        self.loggingRemindersEnabled = false
        self.budgetAlertsEnabled = false
        self.hapticsEnabled = true
        self.hasCompletedOnboarding = false
        self.appearanceMode = .dark
        self.topGradientColorHex = SpendyDefaultData.topGradientColorHex
        self.topGradientHue = SpendyDefaultData.topGradientHue
        self.topGradientBrightness = SpendyDefaultData.topGradientBrightness
        self.isGradientBackgroundEnabled = SpendyDefaultData.isGradientBackgroundEnabled
        self.accounts = Account.defaultAccounts
        self.customFolders = []
        self.categories = Category.defaultExpenseCategories + Category.defaultIncomeCategories
        self.subscriptions = []
        self.transactions = []
        self.budget = Budget()
        self.currencySymbol = SpendyDefaultData.currencySymbol
        self.currencyCode = SpendyDefaultData.currencyCode
        scheduleSave()
    }
    
    func resetOnboarding() {
        self.hasCompletedOnboarding = false
        scheduleSave()
    }
    
    // MARK: - Computed Properties
    
    /// Calculate current live balance for each account
    var accountBalances: [String: Double] {
        if let cached = _cachedBalances {
            return cached
        }
        let balances = Self.calculateAccountBalances(accounts: accounts, transactions: transactions)
        _cachedBalances = balances
        return balances
    }

    static func calculateAccountBalances(accounts: [Account], transactions: [Transaction]) -> [String: Double] {
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
                    // Accounts share one app currency, so a transfer preserves the total balance.
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
        if _cachedCategoryMap == nil {
            var map: [String: Category] = [:]
            for cat in categories {
                map[cat.id] = cat
            }
            _cachedCategoryMap = map
        }
        if let found = _cachedCategoryMap?[id] {
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
        if _cachedAccountMap == nil {
            var map: [String: Account] = [:]
            for acc in accounts {
                map[acc.id] = acc
            }
            _cachedAccountMap = map
        }
        if let found = _cachedAccountMap?[id] {
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
        var transaction = transaction
        if transaction.type == .transfer { transaction.toAmount = transaction.amount }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            transactions.insert(transaction, at: 0)
        }
        HapticsManager.shared.trigger(.success)
    }

    func addTransactionFromIntent(_ transaction: Transaction) {
        var transaction = transaction
        if transaction.type == .transfer { transaction.toAmount = transaction.amount }
        transactions.insert(transaction, at: 0)
        flushPendingSave()
    }

    func ingestPendingWidgetTransactions() {
        guard loadError == nil else { return }
        let pending = WidgetDataManager.shared.loadPendingTransactions()
        guard !pending.isEmpty else { return }

        var didInsert = false
        for item in pending {
            let id = UUID(uuidString: item.id) ?? UUID()
            if transactions.contains(where: { $0.id == id }) { continue }
            let accountId = accounts.contains(where: { $0.id == item.accountId })
                ? item.accountId
                : (accounts.first(where: { $0.id == "cash" })?.id ?? accounts.first?.id ?? "cash")
            let txType: TransactionType = item.isTransfer ? .transfer : (item.isExpense ? .expense : .income)
            let toId = item.isTransfer ? item.toAccountId : nil
            transactions.insert(
                Transaction(
                    id: id,
                    title: item.title,
                    amount: item.amount,
                    type: txType,
                    categoryId: item.categoryId,
                    accountId: accountId,
                    toAccountId: toId,
                    date: item.date,
                    notes: item.notes
                ),
                at: 0
            )
            didInsert = true
        }

        if didInsert { flushPendingSave() }
        if persistenceError == nil {
            WidgetDataManager.shared.acknowledgePendingTransactions(ids: Set(pending.map(\.id)))
        }
        if didInsert { HapticsManager.shared.trigger(.success) }
    }
    
    func deleteTransaction(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            transactions.removeAll(where: { $0.id == id })
        }
        HapticsManager.shared.trigger(.medium)
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            var transaction = transaction
            if transaction.type == .transfer { transaction.toAmount = transaction.amount }
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
        guard accounts.count > 1, accounts.contains(where: { $0.id == id }) else { return }
        if let fallbackId, (fallbackId == id || !accounts.contains(where: { $0.id == fallbackId })) { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let resolvedFallback = fallbackId ?? accounts.first(where: { $0.id != id })?.id
            if let fallbackId = resolvedFallback {
                for i in 0..<transactions.count {
                    if transactions[i].accountId == id {
                        transactions[i].accountId = fallbackId
                    }
                    if transactions[i].toAccountId == id {
                        transactions[i].toAccountId = fallbackId
                    }
                }
                for i in 0..<subscriptions.count {
                    if subscriptions[i].accountId == id {
                        subscriptions[i].accountId = fallbackId
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
                notes: "Subscription payment for \(sub.name)",
                subscriptionId: sub.id.uuidString
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
    
    /// Total monthly normalized committed amount for all active, non-trial subscriptions
    var totalMonthlySubscriptionCommitted: Double {
        subscriptions.filter { !$0.isPaused && !$0.isTrial && !$0.isCancelled }.reduce(0.0) { sum, sub in
            switch sub.cycle {
            case .monthly: return sum + sub.amount
            case .yearly:  return sum + (sub.amount / 12.0)
            case .weekly:  return sum + (sub.amount * 4.33)
            }
        }
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
            .filter { $0.type == .expense && $0.date >= start && $0.date < end && $0.date <= Date() }
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
        
        let facts = budgetInsightFacts()
        let totalDays = facts.totalDaysInCycle
        let elapsedDays = facts.elapsedDays

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
    func budgetInsightFacts(for date: Date = Date()) -> InsightFacts {
        let start = budgetCycleStart(for: date)
        let unit: Calendar.Component = budget.period == .weekly ? .weekOfYear : .month
        return InsightFactsExtractor.extractFacts(transactions: transactions, budget: budget,
            categories: categories, subscriptions: subscriptions,
            context: AnalyticsInsightContext(period: budget.period == .weekly ? .week : .month,
                startDate: start, endDate: budgetCycleEnd(for: date).addingTimeInterval(-1),
                baselineStartDate: Calendar.current.date(byAdding: unit, value: -1, to: start) ?? start,
                baselineEndDate: start.addingTimeInterval(-1), referenceDate: date))
    }

    var budgetPacingInsightMessage: String? {
        guard budget.isActive else { return nil }
        let moment = InsightDecisionEngine.shared.evaluate(facts: budgetInsightFacts(), surface: .budget,
            currencySymbol: currencySymbol).first { !$0.isInsufficientData }
        return moment.map { [$0.headline, $0.supportingText].compactMap { $0 }.joined(separator: " ") }
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
        self.currencySymbol = Self.displayCurrencySymbol(symbol, code: code)
        self.currencyCode = code
        HapticsManager.shared.trigger(.selection)
    }
    
    func refreshExchangeRates(force: Bool = false, session: URLSession = .shared) async {
        guard !isRefreshingRates else { return }
        if !force, let nextCheck = ratesNextUpdate, Date() < nextCheck { return }

        isRefreshingRates = true
        ratesError = nil
        defer { isRefreshingRates = false }

        do {
            let url = URL(string: "https://open.er-api.com/v6/latest/USD")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw ExchangeRateError.invalidResponse
            }
            struct APIResponse: Decodable {
                let result: String
                let base_code: String
                let time_last_update_unix: TimeInterval
                let time_next_update_unix: TimeInterval
                let rates: [String: Double]
            }
            let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
            let validRates = decoded.rates.filter { $0.value.isFinite && $0.value > 0 }
            guard decoded.result == "success", decoded.base_code == "USD",
                  validRates.count > 20, validRates["USD"] == 1,
                  decoded.time_last_update_unix > 0,
                  decoded.time_next_update_unix > decoded.time_last_update_unix else {
                throw ExchangeRateError.invalidResponse
            }
            ratesToUSD = validRates
            ratesLastUpdated = Date(timeIntervalSince1970: decoded.time_last_update_unix)
            ratesNextUpdate = Date(timeIntervalSince1970: decoded.time_next_update_unix)
        } catch {
            ratesError = "Couldn't update rates. Check your connection and try again."
        }
    }

    private enum ExchangeRateError: Error {
        case invalidResponse
    }

    
    func resetToSampleData() {
        self.userName = SpendyDefaultData.userName
        self.soundEnabled = true
        self.insightsEnabled = true
        self.weeklySummaryEnabled = false
        self.loggingRemindersEnabled = false
        self.budgetAlertsEnabled = false
        self.hapticsEnabled = true
        self.hasCompletedOnboarding = true
        self.appearanceMode = SpendyDefaultData.appearanceMode
        self.topGradientColorHex = SpendyDefaultData.topGradientColorHex
        self.topGradientHue = SpendyDefaultData.topGradientHue
        self.topGradientBrightness = SpendyDefaultData.topGradientBrightness
        self.isGradientBackgroundEnabled = SpendyDefaultData.isGradientBackgroundEnabled
        self.accounts = SpendyDefaultData.accounts
        self.customFolders = SpendyDefaultData.customFolders
        self.categories = SpendyDefaultData.categories
        self.subscriptions = SpendyDefaultData.subscriptions
        self.transactions = SpendyDefaultData.transactions
        self.budget = SpendyDefaultData.budget
        self.currencySymbol = SpendyDefaultData.currencySymbol
        self.currencyCode = SpendyDefaultData.currencyCode
        scheduleSave()
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
        _saveTask?.cancel()
        saveToDisk(flush: true, clearRecovery: true)
    }
    
    func exportJSONData() -> Data? {
        let payload = StoragePayload(
            userName: userName,
            hapticsEnabled: hapticsEnabled,
            profileImageData: profileImageData,
            profileIconSymbol: profileIconSymbol,
            profileColorHex: profileColorHex,
            soundEnabled: soundEnabled,
            insightsEnabled: insightsEnabled,
            weeklySummaryEnabled: weeklySummaryEnabled,
            loggingRemindersEnabled: loggingRemindersEnabled,
            budgetAlertsEnabled: budgetAlertsEnabled,
            notificationsEnabled: notificationsEnabled,
            appearanceMode: appearanceMode,
            isMonoIconMode: isMonoIconMode,
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
            showHomeSpendBarChart: isSectionVisible(.spendingChart),
            showHomeBudgetCard: isSectionVisible(.budget),
            showHomeSmartInsights: isSectionVisible(.spendingByCategory),
            showHomeAccountsCard: isSectionVisible(.accounts),
            dashboardSectionOrder: dashboardSectionOrder.map { $0.rawValue },
            dashboardHiddenSections: dashboardHiddenSections,
            customFolders: customFolders,
            ratesToUSD: ratesToUSD,
            ratesLastUpdated: ratesLastUpdated,
            ratesNextUpdate: ratesNextUpdate,
            hasCompletedOnboarding: hasCompletedOnboarding,
            selectedSticker: nil
        )
        return try? ExpenseStore.jsonEncoder.encode(payload)
    }
    
    func exportCSVData() -> Data? {
        var csv = "Date,Time,Title,Type,Amount,Currency,Category,Account,To Account,Notes\r\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.label) })
        let accountLookup = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.label) })
        
        func escapeCSV(_ string: String) -> String {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r") {
                return "\"\(escaped)\""
            }
            return escaped
        }
        
        let sortedTransactions = transactions.sorted { $0.date > $1.date }
        
        for tx in sortedTransactions {
            let dateStr = dateFormatter.string(from: tx.date)
            let timeStr = timeFormatter.string(from: tx.date)
            let titleStr = escapeCSV(tx.title)
            let typeStr = tx.type.rawValue.capitalized
            let amountStr = String(format: "%.2f", tx.amount)
            let currencyStr = currencyCode
            let catName = escapeCSV(categoryLookup[tx.categoryId] ?? tx.categoryId)
            let accName = escapeCSV(accountLookup[tx.accountId] ?? tx.accountId)
            let toAccName = tx.toAccountId.flatMap { escapeCSV(accountLookup[$0] ?? $0) } ?? ""
            let notesStr = escapeCSV(tx.notes ?? "")
            
            let row = "\(dateStr),\(timeStr),\(titleStr),\(typeStr),\(amountStr),\(currencyStr),\(catName),\(accName),\(toAccName),\(notesStr)\r\n"
            csv.append(row)
        }
        
        return csv.data(using: .utf8)
    }
    
    func importJSONData(data: Data) -> Bool {
        do {
            let payload = try ExpenseStore.jsonDecoder.decode(StoragePayload.self, from: data)
            try Self.validate(payload)
            withAnimation(.spring(response: 0.35)) {
                self.userName = payload.userName ?? self.userName
                self.profileImageData = payload.profileImageData
                self.profileIconSymbol = payload.profileIconSymbol
                self.profileColorHex = payload.profileColorHex
                self.insightsEnabled = payload.insightsEnabled ?? self.insightsEnabled
                self.weeklySummaryEnabled = payload.weeklySummaryEnabled ?? self.weeklySummaryEnabled
                self.loggingRemindersEnabled = payload.loggingRemindersEnabled ?? self.loggingRemindersEnabled
                self.budgetAlertsEnabled = payload.budgetAlertsEnabled ?? self.budgetAlertsEnabled
                self.notificationsEnabled = payload.notificationsEnabled ?? self.notificationsEnabled
                self.ratesLastUpdated = payload.ratesLastUpdated
                self.ratesNextUpdate = payload.ratesNextUpdate
                self.ratesToUSD = payload.ratesToUSD ?? ["USD": 1]
                self.dashboardHiddenSections = payload.dashboardHiddenSections ?? []
                if let raw = payload.dashboardSectionOrder {
                    let order = raw.compactMap(DashboardSectionId.init(rawValue:))
                    self.dashboardSectionOrder = order + DashboardSectionId.allCases.filter { !order.contains($0) }
                }
                self.soundEnabled = payload.soundEnabled ?? self.soundEnabled
                self.hapticsEnabled = payload.hapticsEnabled ?? self.hapticsEnabled
                self.appearanceMode = payload.appearanceMode ?? self.appearanceMode
                self.isMonoIconMode = true
                SpendyColors.isMonoMode = self.isMonoIconMode
                self.topGradientColorHex = payload.topGradientColorHex ?? self.topGradientColorHex
                self.isGradientBackgroundEnabled = payload.isGradientBackgroundEnabled ?? self.isGradientBackgroundEnabled
                self.topGradientHue = payload.topGradientHue ?? self.topGradientHue
                self.topGradientBrightness = payload.topGradientBrightness ?? self.topGradientBrightness
                self.transactions = payload.transactions
                self.accounts = payload.accounts
                self.categories = payload.categories
                self.subscriptions = payload.subscriptions
                self.budget = payload.budget
                self.currencySymbol = Self.displayCurrencySymbol(payload.currencySymbol, code: payload.currencyCode)
                self.currencyCode = payload.currencyCode
                
                var folders = payload.customFolders ?? []
                if folders.isEmpty {
                    let defaultFolders = Set(["Everyday Spending", "Transport", "Living", "Personal & Wellness", "Salary & Career", "Investments & Other", "Uncategorized"])
                    for cat in payload.categories {
                        if !cat.folder.isEmpty && !defaultFolders.contains(cat.folder) {
                            if !folders.contains(where: { $0.name == cat.folder && $0.type == cat.type }) {
                                folders.append(Folder(name: cat.folder, type: cat.type))
                            }
                        }
                    }
                }
                self.customFolders = folders
            }
            scheduleSave()
            HapticsManager.shared.trigger(.success)
            return true
        } catch {
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               object["categories"] is [String: Any], importWebExportJSON(data: data) {
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
        
        func parseDate(_ val: Any?) -> Date? {
            if let dStr = val as? String {
                if let d = isoFormatter.date(from: dStr) { return d }
                if let d = isoFormatterNoFrac.date(from: dStr) { return d }
                let df = ISO8601DateFormatter()
                if let d = df.date(from: dStr) { return d }
            } else if let num = val as? NSNumber {
                let ms = num.doubleValue
                if ms > 10_000_000_000 {
                    return Date(timeIntervalSince1970: ms / 1000.0)
                } else {
                    return Date(timeIntervalSince1970: ms)
                }
            }
            return nil
        }
        
        func parseUUID(_ str: String) -> UUID {
            var clean = str
            if clean.hasPrefix("tx_") { clean = String(clean.dropFirst(3)) }
            else if clean.hasPrefix("trans_") { clean = String(clean.dropFirst(6)) }
            else if clean.hasPrefix("sub_") { clean = String(clean.dropFirst(4)) }
            return UUID(uuidString: clean) ?? UUID()
        }
        
        guard let accountRows = jsonObject["accounts"] as? [[String: Any]],
              let transactionRows = jsonObject["transactions"] as? [[String: Any]],
              jsonObject["categories"] is [String: Any] else { return false }
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
                    if id.lowercased() == "bank2" { return "#FF9500" }
                    if id.lowercased() == "bank" { return "#007AFF" }
                    return "#007AFF"
                }()
                let accType: AccountType = id.lowercased().contains("cash") ? .cash : .bank
                let opBal = (dict["openingBalance"] as? NSNumber)?.doubleValue ?? 0.0
                newAccounts.append(Account(id: id, label: label, sfSymbol: symbol, colorHex: defaultColor, openingBalance: opBal, order: idx, type: accType))
            }
        }
        
        var newCategories: [Category] = []
        if let catObj = jsonObject["categories"] as? [String: Any] {
            let sfMap: [String: String] = [
                "fastfood": SFIcons.food,
                "gas": SFIcons.fuel,
                "groceries": SFIcons.groceries,
                "movies": SFIcons.entertainment,
                "savings": SFIcons.savings,
                "receipt": "receipt",
                "spa": "leaf.fill",
                "pets": SFIcons.pets,
                "home": SFIcons.housing,
                "amazon": SFIcons.delivery,
                "cut": "scissors",
                "golf": SFIcons.transport,
                "favorite": SFIcons.health,
                "drycleaning": SFIcons.shopping,
                "glasses": "eyeglasses",
                "brush": "pencil.and.ruler.fill",
                "atm": SFIcons.creditCard,
                "card_ri": "creditcard.fill",
                "medical": "cross.case.fill",
                "car_ri": "tram.fill",
                "money": SFIcons.paycheck,
                "work": SFIcons.freelance,
                "gift": SFIcons.gifts,
                "family": "figure.2.and.child.holdinghands",
                "Tag": "tag.fill"
            ]
            
            func parseCatList(_ list: [[String: Any]], _ type: TransactionType) {
                for (idx, dict) in list.enumerated() {
                    guard let id = dict["id"] as? String, let label = dict["label"] as? String else { continue }
                    let color = dict["color"] as? String ?? (type == .income ? "#30D158" : "#3478F6")
                    let iconName = dict["iconName"] as? String ?? ""
                    let symbol = sfMap[iconName] ?? (type == .income ? "banknote.fill" : "tag.fill")
                    let hidden = dict["hidden"] as? Bool ?? false
                    let folder = dict["folder"] as? String ?? (type == .income ? "Salary & Career" : "Everyday Spending")
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
                let cycleStr = dict["cycle"] as? String ?? dict["billingCycle"] as? String ?? "monthly"
                let cycle = BillingCycle(rawValue: cycleStr) ?? .monthly
                let dateVal = dict["nextBillingDate"] ?? dict["nextBilling"] ?? dict["startDate"] ?? dict["originalDate"]
                guard let date = parseDate(dateVal) else { return false }
                let accountId = dict["accountId"] as? String ?? "bank"
                let isTrial = dict["isTrial"] as? Bool ?? false
                let isPaused = dict["isPaused"] as? Bool ?? false
                let status = dict["status"] as? String ?? "active"
                
                let sfSym: String = {
                    if name.localizedCaseInsensitiveContains("apple") { return "apple.logo" }
                    if name.localizedCaseInsensitiveContains("weather") { return "cloud.sun.fill" }
                    if name.localizedCaseInsensitiveContains("instagram") { return "camera.fill" }
                    if name.localizedCaseInsensitiveContains("whatsapp") { return "bubble.left.and.bubble.right.fill" }
                    if name.localizedCaseInsensitiveContains("gemini") { return "sparkles" }
                    return SFIcons.subscriptions
                }()
                
                newSubscriptions.append(Subscription(
                    id: parseUUID(idStr),
                    name: name,
                    amount: amtNum.doubleValue,
                    cycle: cycle,
                    nextBillingDate: date,
                    categoryId: "subscriptions",
                    accountId: accountId,
                    autoDeduct: false,
                    isPaused: isPaused || status == "paused",
                    isTrial: isTrial,
                    status: status,
                    sfSymbol: sfSym,
                    colorHex: "#5856D6",
                    isDarkBadge: true
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
                      let accId = dict["accountId"] as? String else { continue }
                
                guard let txDate = parseDate(dict["date"]), let txType = TransactionType(rawValue: typeStr) else { return false }
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
        
        var derivedFolders: [Folder] = []
        let defaultFolders = Set(["Everyday Spending", "Transport", "Living", "Personal & Wellness", "Salary & Career", "Investments & Other", "Uncategorized"])
        for cat in newCategories {
            if !cat.folder.isEmpty && !defaultFolders.contains(cat.folder) {
                if !derivedFolders.contains(where: { $0.name == cat.folder && $0.type == cat.type }) {
                    derivedFolders.append(Folder(name: cat.folder, type: cat.type))
                }
            }
        }
        
        guard newAccounts.count == accountRows.count,
              newTransactions.count == transactionRows.count,
              Set(newAccounts.map(\.id)).count == newAccounts.count,
              Set(newCategories.map(\.id)).count == newCategories.count,
              Set(newTransactions.map(\.id)).count == newTransactions.count,
              newBudget.amount.isFinite, newBudget.amount >= 0,
              Set(newSubscriptions.map(\.id)).count == newSubscriptions.count,
              newSubscriptions.count == (jsonObject["subscriptions"] as? [[String: Any]] ?? []).count,
              newSubscriptions.allSatisfy({ sub in sub.amount.isFinite && sub.amount >= 0 && newAccounts.contains(where: { $0.id == sub.accountId }) }),
              newAccounts.allSatisfy({ $0.openingBalance.isFinite }),
              newTransactions.allSatisfy({ tx in
                  tx.amount.isFinite && tx.amount >= 0
                  && newAccounts.contains(where: { $0.id == tx.accountId })
                  && (tx.type != .transfer || (tx.toAccountId != tx.accountId && newAccounts.contains(where: { $0.id == tx.toAccountId })))
              }) else { return false }

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
            if !derivedFolders.isEmpty { self.customFolders = derivedFolders }
            self.transactions = newTransactions
        }
        
        scheduleSave()
        HapticsManager.shared.trigger(.success)
        return true
    }
}
