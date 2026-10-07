//
//  SpendyLiveActivityAttributes.swift
//  Spendy
//
//  ActivityKit Attributes & Dynamic State for Daily Budget Pacing & Upcoming Subscriptions
//  Shared across the Main App, Widget Extension, and Dynamic Island.
//

import ActivityKit
import Foundation
import SwiftUI

public struct BudgetPacingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var spentToday: Double
        public var dailyBudget: Double
        public var remainingToday: Double
        public var pacingPercent: Double // 0.0 to 1.0+
        public var statusText: String    // e.g. "On Track", "62% spent", "Over Budget"
        public var statusColorHex: String // e.g. "#34C759", "#FF9500", "#FF3B30"
        public var nextSubscriptionTitle: String?
        public var nextSubscriptionAmount: Double?
        public var nextSubscriptionDueDays: Int?
        public var lastUpdated: Date
        
        public init(
            spentToday: Double,
            dailyBudget: Double,
            remainingToday: Double,
            pacingPercent: Double,
            statusText: String,
            statusColorHex: String,
            nextSubscriptionTitle: String? = nil,
            nextSubscriptionAmount: Double? = nil,
            nextSubscriptionDueDays: Int? = nil,
            lastUpdated: Date = Date()
        ) {
            self.spentToday = spentToday
            self.dailyBudget = dailyBudget
            self.remainingToday = remainingToday
            self.pacingPercent = pacingPercent
            self.statusText = statusText
            self.statusColorHex = statusColorHex
            self.nextSubscriptionTitle = nextSubscriptionTitle
            self.nextSubscriptionAmount = nextSubscriptionAmount
            self.nextSubscriptionDueDays = nextSubscriptionDueDays
            self.lastUpdated = lastUpdated
        }
    }
    
    public var currencySymbol: String
    public var budgetCycleName: String
    
    public init(currencySymbol: String = "$", budgetCycleName: String = "Daily Budget") {
        self.currencySymbol = currencySymbol
        self.budgetCycleName = budgetCycleName
    }
}
