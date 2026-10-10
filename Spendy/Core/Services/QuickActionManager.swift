//
//  QuickActionManager.swift
//  Spendy
//
//  Central Coordinator for Home Screen Quick Actions, Deep Links, and App Intents
//

import SwiftUI
import UIKit
import Observation

@Observable
@MainActor
final class QuickActionManager {
    static let shared = QuickActionManager()
    
    // Observable UI Triggers
    var shouldPresentQuickAdd: Bool = false
    var shouldPresentReceiptScan: Bool = false
    var targetTab: AppTab? = nil
    var requestedAnalyticsWeekDate: Date? = nil
    var shouldOpenBudget: Bool = false
    var requestedCategoryId: String? = nil
    
    // Shortcut Item Types
    enum ShortcutType: String {
        case quickAdd = "com.spendy.quickadd"
        case analytics = "com.spendy.analytics"
    }
    
    private init() {}
    
    /// Registers dynamic Home Screen 3D / Haptic Touch shortcut items
    func registerDynamicShortcuts() {
        let quickAdd = UIApplicationShortcutItem(
            type: ShortcutType.quickAdd.rawValue,
            localizedTitle: "Quick Add Expense",
            localizedSubtitle: "Log a new transaction",
            icon: UIApplicationShortcutIcon(type: .add),
            userInfo: nil
        )
        
        let analytics = UIApplicationShortcutItem(
            type: ShortcutType.analytics.rawValue,
            localizedTitle: "Analytics",
            localizedSubtitle: "View spending breakdown",
            icon: UIApplicationShortcutIcon(type: .time),
            userInfo: nil
        )
        
        UIApplication.shared.shortcutItems = [quickAdd, analytics]
    }
    
    /// Handles shortcut items triggered from the Home Screen icon
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        guard let type = ShortcutType(rawValue: shortcutItem.type) else { return }
        
        switch type {
        case .quickAdd:
            triggerQuickAdd()
        case .analytics:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.targetTab = .analytics
            }
        }
    }
    
    /// Triggers immediate Quick Add presentation with sensory feedback
    func triggerQuickAdd() {
        HapticsManager.shared.trigger(.selection)
        withAnimation(.spring(response: 0.40, dampingFraction: 0.86)) {
            self.shouldPresentQuickAdd = true
        }
    }

    /// Siri / App Intents path — no haptics or animation, so launch cannot fail.
    func presentQuickAddFromIntent() {
        shouldPresentQuickAdd = true
    }

    func presentReceiptScan() {
        shouldPresentReceiptScan = true
    }
    
    /// Handles deep link URLs (e.g. spendy://quick-add or spendy://analytics)
    func handleURL(_ url: URL) {
        guard url.scheme?.lowercased() == "spendy" else { return }
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        if host == "scan" {
            presentReceiptScan()
        } else if host == "quick-add" || host == "log" || path.contains("quick-add") || path.contains("log") {
            triggerQuickAdd()
        } else if host == "budget" {
            targetTab = .home
            shouldOpenBudget = true
        } else if host == "category", let categoryId = url.pathComponents.dropFirst().first {
            targetTab = .home
            requestedCategoryId = categoryId
        } else if host == "home" || path.contains("home") {
            return
        } else if host == "weekly-summary" {
            requestedAnalyticsWeekDate = url.pathComponents.dropFirst().first.flatMap(Double.init).map { Date(timeIntervalSince1970: $0) } ?? Date()
            targetTab = .analytics
        } else if host == "analytics" || path.contains("analytics") {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.targetTab = .analytics
            }
        } else if host == "subscriptions" || path.contains("subscriptions") {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.targetTab = .subscriptions
            }
        }
    }
}
