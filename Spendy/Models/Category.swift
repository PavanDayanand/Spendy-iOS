//
//  Category.swift
//  Spendy
//
//  Category Model with Pure SF Symbols and Custom Colors
//

import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id: String
    var label: String
    var sfSymbol: String
    var colorHex: String
    var type: TransactionType
    var isHidden: Bool
    var order: Int
    
    init(
        id: String,
        label: String,
        sfSymbol: String,
        colorHex: String,
        type: TransactionType = .expense,
        isHidden: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.label = label
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.type = type
        self.isHidden = isHidden
        self.order = order
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // MARK: - Default Expense Categories (Pure SF Symbols)
    static let defaultExpenseCategories: [Category] = [
        Category(id: "food", label: "Food & Dining", sfSymbol: SFIcons.food, colorHex: "#FF9500", type: .expense, order: 0),
        Category(id: "transport", label: "Transport", sfSymbol: SFIcons.transport, colorHex: "#007AFF", type: .expense, order: 1),
        Category(id: "groceries", label: "Groceries", sfSymbol: SFIcons.groceries, colorHex: "#AF52DE", type: .expense, order: 2),
        Category(id: "entertainment", label: "Entertainment", sfSymbol: SFIcons.entertainment, colorHex: "#FF453A", type: .expense, order: 3),
        Category(id: "shopping", label: "Shopping", sfSymbol: SFIcons.shopping, colorHex: "#FF2D55", type: .expense, order: 4),
        Category(id: "subscriptions", label: "Subscriptions", sfSymbol: SFIcons.subscriptions, colorHex: "#5856D6", type: .expense, order: 5),
        Category(id: "housing", label: "Housing & Rent", sfSymbol: SFIcons.housing, colorHex: "#34C759", type: .expense, order: 6),
        Category(id: "utilities", label: "Bills & Utilities", sfSymbol: SFIcons.utilities, colorHex: "#FFCC00", type: .expense, order: 7),
        Category(id: "health", label: "Health & Fitness", sfSymbol: SFIcons.health, colorHex: "#FF375F", type: .expense, order: 8),
        Category(id: "travel", label: "Travel", sfSymbol: SFIcons.travel, colorHex: "#32ADE6", type: .expense, order: 9)
    ]
    
    // MARK: - Default Income Categories (Pure SF Symbols)
    static let defaultIncomeCategories: [Category] = [
        Category(id: "paycheck", label: "Salary / Paycheck", sfSymbol: SFIcons.paycheck, colorHex: "#30D158", type: .income, order: 0),
        Category(id: "freelance", label: "Freelance / Work", sfSymbol: SFIcons.freelance, colorHex: "#007AFF", type: .income, order: 1),
        Category(id: "investment", label: "Investments", sfSymbol: SFIcons.investment, colorHex: "#FFD60A", type: .income, order: 2),
        Category(id: "refund", label: "Refunds", sfSymbol: SFIcons.refund, colorHex: "#FF9500", type: .income, order: 3),
        Category(id: "gift", label: "Gifts", sfSymbol: SFIcons.gift, colorHex: "#AF52DE", type: .income, order: 4),
        Category(id: "bonus", label: "Bonus", sfSymbol: SFIcons.bonus, colorHex: "#32ADE6", type: .income, order: 5)
    ]
}
