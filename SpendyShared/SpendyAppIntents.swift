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

nonisolated struct CategoryAppEntity: AppEntity, Identifiable, Sendable {
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
            image: .init(
                systemName: sfSymbol,
                tintColor: UIColor(SpendyHexColor.color(from: colorHex))
            )
        )
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

nonisolated struct LogTransactionIntent: AppIntent {
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

nonisolated struct SpendyHomeWidgetIntent: WidgetConfigurationIntent {
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
