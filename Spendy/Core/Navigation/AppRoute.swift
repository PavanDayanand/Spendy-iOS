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
    
    static func subscriptionRow(_ id: UUID) -> String {
        "subscription_row_\(id.uuidString)"
    }

    static func nextBill(_ id: UUID) -> String {
        "next_bill_\(id.uuidString)"
    }

    static let quickAddButton = "quick_add_fab"
    static let subscriptionsButton = "subscriptions_widget_button"
    static let accountsButton = "accounts_widget_button"
    static let budgetHealthCard = "budget_health_card"
}


// MARK: - Native navigation transitions
// Keep source/destination pairs in the presenting view's namespace. Optional
// sources let deep links and non-row entry points use the system transition.
private struct SpendyNavigationSourceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let id: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if !reduceMotion, let id, let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct SpendyNavigationZoomModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let id: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if !reduceMotion, let id, let namespace {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

extension View {
    func spendyNavigationSource(_ id: String?, in namespace: Namespace.ID?) -> some View {
        modifier(SpendyNavigationSourceModifier(id: id, namespace: namespace))
    }

    func spendyNavigationZoom(from id: String?, in namespace: Namespace.ID?) -> some View {
        modifier(SpendyNavigationZoomModifier(id: id, namespace: namespace))
    }
}
