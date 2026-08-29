//
//  AppRoute.swift
//  Spendy
//
//  Type-Safe Navigation Destinations and Hero Transition Identifiers
//

import SwiftUI

// MARK: - App Navigation Routes (Blueprint §4 & §68)
enum AppRoute: Hashable, Identifiable {
    case categoryDetail(Category)
    case accountDetail(Account)
    case subscriptions
    case accountsHub
    case smartInsights
    case settings(SettingsDestination?)
    
    var id: String {
        switch self {
        case .categoryDetail(let cat):
            return "category_\(cat.id)"
        case .accountDetail(let acc):
            return "account_\(acc.id)"
        case .subscriptions:
            return "subscriptions"
        case .accountsHub:
            return "accountsHub"
        case .smartInsights:
            return "smartInsights"
        case .settings(let dest):
            return "settings_\(dest?.hashValue ?? 0)"
        }
    }
}

// MARK: - Zoom Transition Helpers (Blueprint §17, §18, §71)
enum AppTransitionIDs {
    static func categoryCard(_ id: String) -> String {
        "category_card_\(id)"
    }
    
    static func accountCard(_ id: String) -> String {
        "account_card_\(id)"
    }
    
    static func insightCard(_ id: String) -> String {
        "insight_card_\(id)"
    }
    
    static let quickAddButton = "quick_add_fab"
    static let subscriptionsButton = "subscriptions_widget_button"
    static let accountsButton = "accounts_widget_button"
    static let budgetHealthCard = "budget_health_card"
}

