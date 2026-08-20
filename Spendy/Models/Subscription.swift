//
//  Subscription.swift
//  Spendy
//
//  Recurring Subscriptions with Pure SF Symbols
//

import SwiftUI

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case monthly
    case yearly
    case weekly
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .weekly: return "Weekly"
        }
    }
}

struct Subscription: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var amount: Double
    var cycle: BillingCycle
    var nextBillingDate: Date
    var categoryId: String
    var accountId: String
    var autoDeduct: Bool
    var isPaused: Bool
    var sfSymbol: String
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        cycle: BillingCycle = .monthly,
        nextBillingDate: Date = Date(),
        categoryId: String = "subscriptions",
        accountId: String = "bank",
        autoDeduct: Bool = false,
        isPaused: Bool = false,
        sfSymbol: String = SFIcons.subscriptions,
        colorHex: String = "#5856D6"
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.cycle = cycle
        self.nextBillingDate = nextBillingDate
        self.categoryId = categoryId
        self.accountId = accountId
        self.autoDeduct = autoDeduct
        self.isPaused = isPaused
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // MARK: - Default Subscriptions
    static let samples: [Subscription] = []
}
