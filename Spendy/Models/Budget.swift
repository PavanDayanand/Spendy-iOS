//
//  Budget.swift
//  Spendy
//
//  Budget tracking and category limits
//

import Foundation

enum BudgetPeriod: String, Codable, CaseIterable, Identifiable {
    case monthly = "monthly"
    case weekly = "weekly"
    
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Budget: Codable, Hashable {
    var amount: Double
    var period: BudgetPeriod
    var startDay: Int // 1...28
    var isActive: Bool
    var categoryBudgets: [String: Double]
    
    init(
        amount: Double = 0.0,
        period: BudgetPeriod = .monthly,
        startDay: Int = 1,
        isActive: Bool = false,
        categoryBudgets: [String: Double] = [:]
    ) {
        self.amount = amount
        self.period = period
        self.startDay = min(max(startDay, 1), 28)
        self.isActive = isActive
        self.categoryBudgets = categoryBudgets
    }
    
    enum CodingKeys: String, CodingKey {
        case amount
        case period
        case startDay
        case isActive
        case categoryBudgets
        // Legacy key
        case monthlyBudget
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let catBudgets = try container.decodeIfPresent([String: Double].self, forKey: .categoryBudgets) ?? [:]
        self.categoryBudgets = catBudgets
        
        if let amt = try container.decodeIfPresent(Double.self, forKey: .amount) {
            self.amount = amt
            self.period = try container.decodeIfPresent(BudgetPeriod.self, forKey: .period) ?? .monthly
            self.startDay = try container.decodeIfPresent(Int.self, forKey: .startDay) ?? 1
            self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? (amt > 0)
        } else if let legacyMonthly = try container.decodeIfPresent(Double.self, forKey: .monthlyBudget) {
            self.amount = legacyMonthly
            self.period = .monthly
            self.startDay = 1
            self.isActive = legacyMonthly > 0
        } else {
            self.amount = 7800.0
            self.period = .monthly
            self.startDay = 1
            self.isActive = false
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(period, forKey: .period)
        try container.encode(startDay, forKey: .startDay)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(categoryBudgets, forKey: .categoryBudgets)
        // Also encode monthlyBudget for legacy readers if needed
        try container.encode(amount, forKey: .monthlyBudget)
    }
}

