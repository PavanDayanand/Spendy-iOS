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
    var isTrial: Bool
    var status: String // "active", "cancelled", "paused"
    var sfSymbol: String
    var colorHex: String
    var isDarkBadge: Bool
    
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
        isTrial: Bool = false,
        status: String = "active",
        sfSymbol: String = SFIcons.subscriptions,
        colorHex: String = "#5856D6",
        isDarkBadge: Bool = false
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
        self.isTrial = isTrial
        self.status = status
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.isDarkBadge = isDarkBadge
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, cycle, nextBillingDate, categoryId, accountId, autoDeduct, isPaused, isTrial, status, sfSymbol, colorHex, isDarkBadge
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Subscription"
        self.amount = try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0.0
        self.cycle = try container.decodeIfPresent(BillingCycle.self, forKey: .cycle) ?? .monthly
        self.nextBillingDate = try container.decodeIfPresent(Date.self, forKey: .nextBillingDate) ?? Date()
        self.categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId) ?? "subscriptions"
        self.accountId = try container.decodeIfPresent(String.self, forKey: .accountId) ?? "bank"
        self.autoDeduct = try container.decodeIfPresent(Bool.self, forKey: .autoDeduct) ?? false
        self.isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        self.isTrial = try container.decodeIfPresent(Bool.self, forKey: .isTrial) ?? false
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        self.sfSymbol = try container.decodeIfPresent(String.self, forKey: .sfSymbol) ?? SFIcons.subscriptions
        self.colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#5856D6"
        self.isDarkBadge = try container.decodeIfPresent(Bool.self, forKey: .isDarkBadge) ?? false
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var isCancelled: Bool {
        status == "cancelled"
    }
    
    // MARK: - Default Subscriptions
    static let samples: [Subscription] = []
}
