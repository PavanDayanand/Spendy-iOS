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
    
    // MARK: - Default Expense Categories (Vibrant Colors Baked In)
    static let defaultExpenseCategories: [Category] = [
        // Everyday Spending
        Category(id: "groceries", label: "Groceries", sfSymbol: SFIcons.groceries, colorHex: "#34C759", type: .expense, folder: "Everyday Spending", order: 0),
        Category(id: "restaurants", label: "Restaurants", sfSymbol: SFIcons.food, colorHex: "#FF9F0A", type: .expense, folder: "Everyday Spending", order: 1),
        Category(id: "food_delivery", label: "Food Delivery", sfSymbol: "bag.badge.plus", colorHex: "#FF6482", type: .expense, folder: "Everyday Spending", order: 2),
        Category(id: "coffee", label: "Coffee & Cafés", sfSymbol: SFIcons.coffee, colorHex: "#A2845E", type: .expense, folder: "Everyday Spending", order: 3),
        
        // Transport
        Category(id: "public_transport", label: "Public Transport", sfSymbol: "tram.fill.tunnel", colorHex: "#007AFF", type: .expense, folder: "Transport", order: 4),
        Category(id: "fuel", label: "Fuel", sfSymbol: SFIcons.fuel, colorHex: "#FF9500", type: .expense, folder: "Transport", order: 5),
        Category(id: "taxi", label: "Taxi & Ride-hailing", sfSymbol: SFIcons.transport, colorHex: "#FFCC00", type: .expense, folder: "Transport", order: 6),
        Category(id: "car_maintenance", label: "Car Maintenance", sfSymbol: "gearshape.2.fill", colorHex: "#8E8E93", type: .expense, folder: "Transport", order: 7),
        
        // Living
        Category(id: "rent", label: "Rent", sfSymbol: SFIcons.housing, colorHex: "#FF3B30", type: .expense, folder: "Living", order: 8),
        Category(id: "utilities", label: "Utilities", sfSymbol: SFIcons.utilities, colorHex: "#FFD60A", type: .expense, folder: "Living", order: 9),
        Category(id: "subscriptions", label: "Subscriptions", sfSymbol: SFIcons.subscriptions, colorHex: "#AF52DE", type: .expense, folder: "Living", order: 10),
        Category(id: "insurance", label: "Insurance", sfSymbol: SFIcons.insurance, colorHex: "#0A84FF", type: .expense, folder: "Living", order: 11),
        Category(id: "internet_mobile", label: "Internet & Mobile", sfSymbol: SFIcons.internetMobile, colorHex: "#5AC8FA", type: .expense, folder: "Living", order: 12),
        Category(id: "education", label: "Education", sfSymbol: SFIcons.education, colorHex: "#5856D6", type: .expense, folder: "Living", order: 13),
        
        // Personal & Wellness
        Category(id: "shopping", label: "Shopping", sfSymbol: SFIcons.shopping, colorHex: "#5856D6", type: .expense, folder: "Personal & Wellness", order: 14),
        Category(id: "entertainment", label: "Entertainment", sfSymbol: SFIcons.entertainment, colorHex: "#BF5AF2", type: .expense, folder: "Personal & Wellness", order: 15),
        Category(id: "health", label: "Health & Fitness", sfSymbol: SFIcons.health, colorHex: "#FF2D55", type: .expense, folder: "Personal & Wellness", order: 16),
        Category(id: "gifts", label: "Gifts", sfSymbol: SFIcons.gifts, colorHex: "#FF6482", type: .expense, folder: "Personal & Wellness", order: 17),
        Category(id: "beauty", label: "Beauty & Personal Care", sfSymbol: SFIcons.beauty, colorHex: "#FF9FF3", type: .expense, folder: "Personal & Wellness", order: 18),
        Category(id: "clothing", label: "Clothing", sfSymbol: SFIcons.clothing, colorHex: "#AC8E68", type: .expense, folder: "Personal & Wellness", order: 19),
        Category(id: "travel", label: "Travel", sfSymbol: SFIcons.travel, colorHex: "#30B0C7", type: .expense, folder: "Personal & Wellness", order: 20),
        Category(id: "pets", label: "Pets", sfSymbol: SFIcons.pets, colorHex: "#FF9500", type: .expense, folder: "Personal & Wellness", order: 21)
    ]
    
    // MARK: - Default Income Categories (Vibrant Colors Baked In)
    static let defaultIncomeCategories: [Category] = [
        // Salary & Career
        Category(id: "paycheck", label: "Salary / Paycheck", sfSymbol: SFIcons.paycheck, colorHex: "#34C759", type: .income, folder: "Salary & Career", order: 0),
        Category(id: "freelance", label: "Freelance", sfSymbol: SFIcons.freelance, colorHex: "#007AFF", type: .income, folder: "Salary & Career", order: 1),
        Category(id: "bonus", label: "Bonus", sfSymbol: SFIcons.gift, colorHex: "#FFD60A", type: .income, folder: "Salary & Career", order: 2),
        Category(id: "side_hustle", label: "Side Hustle", sfSymbol: SFIcons.sideHustle, colorHex: "#FF9500", type: .income, folder: "Salary & Career", order: 3),
        
        // Investments & Other
        Category(id: "investment", label: "Investments", sfSymbol: SFIcons.investment, colorHex: "#30B0C7", type: .income, folder: "Investments & Other", order: 4),
        Category(id: "refund", label: "Refunds", sfSymbol: SFIcons.refund, colorHex: "#32D74B", type: .income, folder: "Investments & Other", order: 5),
        Category(id: "interest", label: "Interest", sfSymbol: SFIcons.interest, colorHex: "#64D2FF", type: .income, folder: "Investments & Other", order: 6),
        Category(id: "rental_income", label: "Rental Income", sfSymbol: SFIcons.rentalIncome, colorHex: "#FF9F0A", type: .income, folder: "Investments & Other", order: 7),
        Category(id: "dividends", label: "Dividends", sfSymbol: SFIcons.dividends, colorHex: "#5AC8FA", type: .income, folder: "Investments & Other", order: 8),
        Category(id: "gifts_received", label: "Gifts Received", sfSymbol: SFIcons.giftsReceived, colorHex: "#FF6482", type: .income, folder: "Investments & Other", order: 9)
    ]
}
