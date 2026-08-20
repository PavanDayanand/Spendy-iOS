//
//  Budget.swift
//  Spendy
//
//  Budget tracking and category limits
//

import Foundation

struct Budget: Codable, Hashable {
    var monthlyBudget: Double
    var categoryBudgets: [String: Double]
    
    init(
        monthlyBudget: Double = 3000.0,
        categoryBudgets: [String: Double] = [
            "food": 600.0,
            "groceries": 450.0,
            "transport": 200.0,
            "entertainment": 250.0,
            "shopping": 300.0,
            "subscriptions": 100.0
        ]
    ) {
        self.monthlyBudget = monthlyBudget
        self.categoryBudgets = categoryBudgets
    }
}
