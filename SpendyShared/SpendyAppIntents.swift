//
//  SpendyAppIntents.swift
//  Spendy
//
//  Siri / Shortcuts / Action Button — system UI only.
//  Expense or income → category → type the amount → logged snippet.
//

import AppIntents
import SwiftUI
import UIKit
import WidgetKit

enum SpendyIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case missingCategory

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            "Enter an amount greater than zero."
        case .missingCategory:
            "Choose a category."
        }
    }
}

nonisolated enum TransactionTypeAppEnum: String, AppEnum, Sendable {
    case expense = "Expense"
    case income = "Income"

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Type")

    static var caseDisplayRepresentations: [TransactionTypeAppEnum: DisplayRepresentation] = [
        .expense: DisplayRepresentation(title: "Expense", image: .init(systemName: "arrow.up.right")),
        .income: DisplayRepresentation(title: "Income", image: .init(systemName: "arrow.down.left"))
    ]
}

nonisolated struct CategoryAppEntity: IndexedEntity, Identifiable, Sendable {
    static var defaultQuery = CategoryAppEntityQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation("Category")

    var id: String
    var name: String
    var sfSymbol: String
    var colorHex: String
    var isExpense: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            image: .init(systemName: sfSymbol)
        )
    }
}

struct OpenCategoryIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Category"

    @Parameter(title: "Category")
    var target: CategoryAppEntity

    init() {}

    init(target: CategoryAppEntity) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        QuickActionManager.shared.targetTab = .home
        QuickActionManager.shared.requestedCategoryId = target.id
        #endif
        return .result()
    }
}

nonisolated struct CategoryAppEntityQuery: EntityStringQuery, Sendable {
    @IntentParameterDependency<LogTransactionIntent>(\.$type)
    var logIntent

    func entities(for identifiers: [String]) async throws -> [CategoryAppEntity] {
        let lookup = Dictionary(uniqueKeysWithValues: allCategories().map { ($0.id, $0) })
        return identifiers.compactMap { id in lookup[id].map(makeEntity) }
    }

    func suggestedEntities() async throws -> [CategoryAppEntity] {
        let type = logIntent?.type
        return allCategories()
            .filter { record in
                guard !record.isHidden else { return false }
                if type == .income { return !record.isExpense }
                if type == .expense { return record.isExpense }
                return true
            }
            .sorted { $0.order < $1.order }
            .map(makeEntity)
    }

    func entities(matching string: String) async throws -> [CategoryAppEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let suggested = try await suggestedEntities()
        guard !query.isEmpty else { return suggested }
        return suggested.filter { $0.name.lowercased().contains(query) }
    }

    private func allCategories() -> [WidgetCategoryRecord] {
        WidgetDataManager.shared.loadCategories()
    }

    private func makeEntity(_ record: WidgetCategoryRecord) -> CategoryAppEntity {
        CategoryAppEntity(
            id: record.id,
            name: record.name,
            sfSymbol: record.sfSymbol,
            colorHex: record.colorHex,
            isExpense: record.isExpense
        )
    }
}

struct TransactionSnippetView: View {
    let amount: Double
    let currencySymbol: String
    let title: String
    let symbol: String
    let colorHex: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SpendyHexColor.color(from: colorHex))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SpendyHexColor.glyphColor(from: colorHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(SpendyWidgetFormat.amount(amount, symbol: currencySymbol))
                .font(.title3.weight(.semibold).monospacedDigit())
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
    }
}

struct LogTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Transaction"
    static var description = IntentDescription(
        "Log an expense or income in Spendy.",
        categoryName: "Transactions"
    )
    static var openAppWhenRun = false
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var isDiscoverable = true

    static var supportedModes: IntentModes {
        .foreground(.dynamic)
    }

    @Parameter(
        title: "Type",
        requestValueDialog: IntentDialog("Expense or income?")
    )
    var type: TransactionTypeAppEnum?

    @Parameter(
        title: "Category",
        requestValueDialog: IntentDialog("Category")
    )
    var category: CategoryAppEntity?

    @Parameter(
        title: "Amount",
        requestValueDialog: IntentDialog("Amount")
    )
    var amount: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$type) for \(\.$category)") {
            \.$amount
        }
    }

    init() {}

    init(type: TransactionTypeAppEnum?, category: CategoryAppEntity? = nil, amount: Double? = nil) {
        self.type = type
        self.category = category
        self.amount = amount
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let resolvedType: TransactionTypeAppEnum
        if let type {
            resolvedType = type
        } else {
            resolvedType = try await $type.requestValue(IntentDialog("Expense or income?"))
        }

        let resolvedCategory = try await resolveCategory(for: resolvedType)
        let resolvedAmount = try await resolveAmount()
        try save(
            type: resolvedType,
            category: resolvedCategory,
            amount: resolvedAmount
        )

        let symbol = currentCurrencySymbol()
        let formatted = SpendyWidgetFormat.amount(resolvedAmount, symbol: symbol)
        return .result(
            dialog: IntentDialog("Logged \(formatted) for \(resolvedCategory.name)."),
            view: TransactionSnippetView(
                amount: resolvedAmount,
                currencySymbol: symbol,
                title: resolvedCategory.name,
                symbol: resolvedCategory.sfSymbol,
                colorHex: resolvedCategory.colorHex,
                subtitle: resolvedType == .income ? "Income logged" : "Expense logged"
            )
        )
    }

    private func resolveAmount() async throws -> Double {
        if let amount, amount > 0, amount.isFinite {
            return abs(amount)
        }
        let entered = try await $amount.requestValue(IntentDialog("Amount"))
        guard entered > 0, entered.isFinite else { throw SpendyIntentError.invalidAmount }
        return abs(entered)
    }

    private func resolveCategory(for type: TransactionTypeAppEnum) async throws -> CategoryAppEntity {
        if let category {
            return category
        }
        let options = try await CategoryAppEntityQuery().suggestedEntities()
            .filter { type == .income ? !$0.isExpense : $0.isExpense }
        if options.count == 1 {
            return options[0]
        }
        if options.isEmpty {
            return try await $category.requestValue(IntentDialog("Category"))
        }
        return try await $category.requestDisambiguation(
            among: Array(options.prefix(16)),
            dialog: IntentDialog("Category")
        )
    }

    @MainActor
    private func save(
        type: TransactionTypeAppEnum,
        category: CategoryAppEntity,
        amount: Double
    ) throws {
        let isExpense = type == .expense

        #if WIDGET_EXTENSION
        WidgetDataManager.shared.recordLoggedTransaction(
            amount: amount,
            isExpense: isExpense,
            categoryId: category.id,
            categoryName: category.name,
            categorySymbol: category.sfSymbol,
            categoryColorHex: category.colorHex,
            note: nil
        )
        #else
        let store = ExpenseStore.shared
        store.ingestPendingWidgetTransactions()
        let accountId = store.accounts.first(where: { $0.id == "cash" })?.id
            ?? store.accounts.first?.id
            ?? "cash"
        store.addTransactionFromIntent(
            Transaction(
                title: category.name,
                amount: amount,
                type: isExpense ? .expense : .income,
                categoryId: category.id,
                accountId: accountId,
                date: Date(),
                notes: nil
            )
        )
        #endif
    }

    @MainActor
    private func currentCurrencySymbol() -> String {
        #if WIDGET_EXTENSION
        WidgetDataManager.shared.loadSnapshot().currencySymbol
        #else
        ExpenseStore.shared.currencySymbol
        #endif
    }
}

nonisolated struct QuickAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add"
    static var description = IntentDescription(
        "Open Spendy’s keypad to log a transaction.",
        categoryName: "Transactions"
    )
    static var openAppWhenRun = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var isDiscoverable = true

    static var supportedModes: IntentModes {
        .foreground(.immediate)
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        WidgetDataManager.shared.setPendingQuickAdd()
        #if !WIDGET_EXTENSION
        QuickActionManager.shared.presentQuickAddFromIntent()
        #endif
        return .result()
    }
}

nonisolated struct OpenReceiptScannerIntent: AppIntent {
    static var title: LocalizedStringResource = "Scan Receipt"
    static var description = IntentDescription("Open Spendy’s receipt camera.", categoryName: "Transactions")
    static var openAppWhenRun = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var isDiscoverable = true

    static var supportedModes: IntentModes { .foreground(.immediate) }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        QuickActionManager.shared.presentReceiptScan()
        #endif
        return .result()
    }
}

nonisolated enum SpendingPeriodAppEnum: String, AppEnum, Sendable {
    case today
    case week
    case month

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Period")
    static var caseDisplayRepresentations: [SpendingPeriodAppEnum: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today"),
        .week: DisplayRepresentation(title: "Last 7 days"),
        .month: DisplayRepresentation(title: "This month")
    ]

    var spokenName: String {
        switch self {
        case .today: "today"
        case .week: "in the last seven days"
        case .month: "this month"
        }
    }
}

struct SpendingSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Spending"
    static var description = IntentDescription("Find out how much you spent today, in the last seven days, or this month.", categoryName: "Insights")
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var isDiscoverable = true

    @Parameter(title: "Period", default: .today)
    var period: SpendingPeriodAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Check spending for \(\.$period)")
    }

    init() { period = .today }
    init(period: SpendingPeriodAppEnum) { self.period = period }

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        let amount: Double
        switch period {
        case .today: amount = snapshot.todayTotal
        case .week: amount = snapshot.weeklySpending.reduce(0) { $0 + $1.amount }
        case .month: amount = snapshot.monthTotal
        }
        let formatted = SpendyWidgetFormat.amount(amount, symbol: snapshot.currencySymbol)
        return .result(value: amount, dialog: IntentDialog("You spent \(formatted) \(period.spokenName)."))
    }
}

nonisolated struct BudgetStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Budget Room"
    static var description = IntentDescription("Find out what remains in your current budget cycle.", categoryName: "Insights")
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var isDiscoverable = true

    init() {}

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        guard snapshot.budgetTotal > 0 else {
            return .result(value: 0, dialog: IntentDialog("You haven’t set a budget in Spendy yet."))
        }
        let amount = snapshot.budgetOverage > 0 ? snapshot.budgetOverage : snapshot.remainingBudget
        let formatted = SpendyWidgetFormat.amount(amount, symbol: snapshot.currencySymbol)
        let message = snapshot.budgetOverage > 0
            ? "You are \(formatted) over budget."
            : "You have \(formatted) left for this budget cycle, with \(snapshot.daysLeft) days remaining."
        return .result(value: amount, dialog: IntentDialog(stringLiteral: message))
    }
}

struct CategorySpendingIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Category Spending"
    static var description = IntentDescription("Find this month’s spending in a category.", categoryName: "Insights")
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var isDiscoverable = true

    @Parameter(title: "Category", requestValueDialog: IntentDialog("Which category?"))
    var category: CategoryAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Check spending in \(\.$category)")
    }

    init() {}

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        let amount = snapshot.categorySpending.first(where: { $0.id == category.id })?.amount ?? 0
        let formatted = SpendyWidgetFormat.amount(amount, symbol: snapshot.currencySymbol)
        return .result(value: amount, dialog: IntentDialog("You spent \(formatted) on \(category.name) this month."))
    }
}

#if !WIDGET_EXTENSION
nonisolated struct SpendyShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogTransactionIntent(type: .expense),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Record expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "arrow.up.right"
        )

        AppShortcut(
            intent: LogTransactionIntent(type: .income),
            phrases: [
                "Add income in \(.applicationName)",
                "Log income in \(.applicationName)"
            ],
            shortTitle: "Add Income",
            systemImageName: "arrow.down.left"
        )

        AppShortcut(
            intent: LogTransactionIntent(),
            phrases: [
                "Log transaction in \(.applicationName)"
            ],
            shortTitle: "Log Transaction",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: QuickAddExpenseIntent(),
            phrases: [
                "Quick add in \(.applicationName)",
                "Open keypad in \(.applicationName)"
            ],
            shortTitle: "Quick Add",
            systemImageName: "plus"
        )

        AppShortcut(
            intent: OpenReceiptScannerIntent(),
            phrases: ["Scan a receipt in \(.applicationName)"],
            shortTitle: "Scan Receipt",
            systemImageName: "camera.viewfinder"
        )

        AppShortcut(
            intent: SpendingSummaryIntent(period: .today),
            phrases: ["How much did I spend today in \(.applicationName)"],
            shortTitle: "Today’s Spending",
            systemImageName: "chart.bar"
        )

        AppShortcut(
            intent: SpendingSummaryIntent(period: .month),
            phrases: ["How much did I spend this month in \(.applicationName)"],
            shortTitle: "Monthly Spending",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: BudgetStatusIntent(),
            phrases: ["How much budget is left in \(.applicationName)"],
            shortTitle: "Budget Room",
            systemImageName: "circle.dotted"
        )
    }
}
#endif

nonisolated enum SpendyWidgetFocus: String, AppEnum, Sendable {
    case today = "Today"
    case budget = "Budget"
    case week = "This Week"
    case category = "Category"

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Show")

    static var caseDisplayRepresentations: [SpendyWidgetFocus: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today", image: .init(systemName: "sun.max")),
        .budget: DisplayRepresentation(title: "Budget", image: .init(systemName: "circle.dotted")),
        .week: DisplayRepresentation(title: "This Week", image: .init(systemName: "chart.bar")),
        .category: DisplayRepresentation(title: "Category", image: .init(systemName: "square.grid.2x2"))
    ]
}

struct SpendyHomeWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Spendy Widget"
    static var description = IntentDescription("Choose Today, Budget, This Week, or a category.")
    static var isDiscoverable = false

    @Parameter(title: "Show", default: .today)
    var focus: SpendyWidgetFocus

    @Parameter(title: "Category")
    var category: CategoryAppEntity?

    init() {
        self.focus = .today
    }

    init(focus: SpendyWidgetFocus, category: CategoryAppEntity? = nil) {
        self.focus = focus
        self.category = category
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$focus)") {
            \.$category
        }
    }
}
