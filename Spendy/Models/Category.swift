//
//  Category.swift
//  Spendy
//
//  Category Model with Folder Grouping, Pure SF Symbols and Custom Colors
//

import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id: String
    var label: String
    var sfSymbol: String
    var colorHex: String
    var type: TransactionType
    var folder: String
    var isHidden: Bool
    var order: Int
    
    init(
        id: String,
        label: String,
        sfSymbol: String,
        colorHex: String,
        type: TransactionType = .expense,
        folder: String = "Uncategorized",
        isHidden: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.label = label
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.type = type
        self.folder = folder
        self.isHidden = isHidden
        self.order = order
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label, sfSymbol, colorHex, type, folder, isHidden, order
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        sfSymbol = try container.decode(String.self, forKey: .sfSymbol)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        type = try container.decode(TransactionType.self, forKey: .type)
        folder = try container.decodeIfPresent(String.self, forKey: .folder) ?? "Uncategorized"
        isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // MARK: - Default Expense Categories (Folder Grouped Monochrome)
    static let defaultExpenseCategories: [Category] = [
        // Everyday Spending
        Category(id: "groceries", label: "Groceries", sfSymbol: "cart.fill", colorHex: "#FFFFFF", type: .expense, folder: "Everyday Spending", order: 0),
        Category(id: "restaurants", label: "Restaurants", sfSymbol: "fork.knife", colorHex: "#18181B", type: .expense, folder: "Everyday Spending", order: 1),
        Category(id: "food_delivery", label: "Food delivery", sfSymbol: "takeoutbag.and.cup.and.straw.fill", colorHex: "#FFFFFF", type: .expense, folder: "Everyday Spending", order: 2),
        
        // Transport
        Category(id: "public_transport", label: "Public transport", sfSymbol: "bus.fill", colorHex: "#18181B", type: .expense, folder: "Transport", order: 3),
        Category(id: "fuel", label: "Fuel", sfSymbol: "fuelpump.fill", colorHex: "#FFFFFF", type: .expense, folder: "Transport", order: 4),
        Category(id: "taxi", label: "Taxi & Ride-hailing", sfSymbol: "car.fill", colorHex: "#18181B", type: .expense, folder: "Transport", order: 5),
        Category(id: "car_maintenance", label: "Car maintenance", sfSymbol: "gearshape.2.fill", colorHex: "#FFFFFF", type: .expense, folder: "Transport", order: 6),
        
        // Living
        Category(id: "rent", label: "Rent", sfSymbol: "house.fill", colorHex: "#18181B", type: .expense, folder: "Living", order: 7),
        Category(id: "utilities", label: "Utilities", sfSymbol: "bolt.fill", colorHex: "#FFFFFF", type: .expense, folder: "Living", order: 8),
        Category(id: "subscriptions", label: "Subscriptions", sfSymbol: "calendar.badge.clock", colorHex: "#18181B", type: .expense, folder: "Living", order: 9),
        
        // Personal & Wellness
        Category(id: "shopping", label: "Shopping", sfSymbol: "bag.fill", colorHex: "#FFFFFF", type: .expense, folder: "Personal & Wellness", order: 10),
        Category(id: "entertainment", label: "Entertainment", sfSymbol: "tv.fill", colorHex: "#18181B", type: .expense, folder: "Personal & Wellness", order: 11),
        Category(id: "health", label: "Health & Fitness", sfSymbol: "heart.fill", colorHex: "#FFFFFF", type: .expense, folder: "Personal & Wellness", order: 12)
    ]
    
    // MARK: - Default Income Categories (Folder Grouped Monochrome)
    static let defaultIncomeCategories: [Category] = [
        // Salary & Career
        Category(id: "paycheck", label: "Salary / Paycheck", sfSymbol: "dollarsign.circle.fill", colorHex: "#FFFFFF", type: .income, folder: "Salary & Career", order: 0),
        Category(id: "freelance", label: "Freelance", sfSymbol: "briefcase.fill", colorHex: "#18181B", type: .income, folder: "Salary & Career", order: 1),
        Category(id: "bonus", label: "Bonus", sfSymbol: "gift.fill", colorHex: "#FFFFFF", type: .income, folder: "Salary & Career", order: 2),
        
        // Investments & Other
        Category(id: "investment", label: "Investments", sfSymbol: "chart.line.uptrend.xyaxis", colorHex: "#18181B", type: .income, folder: "Investments & Other", order: 3),
        Category(id: "refund", label: "Refunds", sfSymbol: "arrow.uturn.left.circle.fill", colorHex: "#FFFFFF", type: .income, folder: "Investments & Other", order: 4),
        Category(id: "interest", label: "Interest", sfSymbol: "percent", colorHex: "#18181B", type: .income, folder: "Investments & Other", order: 5)
    ]
}
