//
//  SpendyLiveActivityManager.swift
//  Spendy
//
//  Manages the lifecycle and real-time state updates of Dynamic Island
//  and Lock Screen Live Activities via ActivityKit.
//

import ActivityKit
import Foundation
import SwiftUI

@MainActor
final class SpendyLiveActivityManager {
    static let shared = SpendyLiveActivityManager()
    
    private init() {}
    
    /// Starts or updates the daily budget pacing Live Activity
    func syncLiveActivity(from store: ExpenseStore) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let state = computeContentState(from: store)
        let attributes = BudgetPacingActivityAttributes(
            currencySymbol: store.currencySymbol,
            budgetCycleName: "Daily Budget"
        )
        
        // Check if an existing activity is already running
        if let existingActivity = Activity<BudgetPacingActivityAttributes>.activities.first {
            Task {
                let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date()))
                await existingActivity.update(content)
            }
        } else {
            do {
                let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date()))
                _ = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Failed to start Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    /// Ends all active budget pacing Live Activities
    func endAllLiveActivities() {
        Task {
            for activity in Activity<BudgetPacingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    
    // MARK: - Helper Computations
    private func computeContentState(from store: ExpenseStore) -> BudgetPacingActivityAttributes.ContentState {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Calculate Daily Budget
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let totalMonthlyBudget = store.budget.amount > 0 ? store.budget.amount : 1500.0
        let dailyBudget: Double = totalMonthlyBudget / Double(max(1, daysInMonth))
        
        // 2. Calculate Today's Expenses
        let todayExpenses = store.transactions.filter {
            $0.type == .expense && calendar.isDateInToday($0.date)
        }
        let spentToday = todayExpenses.reduce(0) { $0 + $1.amount }
        let remainingToday = max(0, dailyBudget - spentToday)
        let pacingPercent = dailyBudget > 0 ? (spentToday / dailyBudget) : 0.0
        
        // 3. Status Text & Color
        let statusText: String
        let statusColorHex: String
        
        if pacingPercent <= 0.65 {
            let leftFormatted = SpendyWidgetFormat.amount(remainingToday, symbol: store.currencySymbol, decimals: 0)
            statusText = "On Track · \(leftFormatted) left"
            statusColorHex = "#34C759" // Green
        } else if pacingPercent <= 0.90 {
            statusText = "Pacing Well · \(Int(pacingPercent * 100))% used"
            statusColorHex = "#30B0C7" // Cyan
        } else if pacingPercent <= 1.0 {
            statusText = "Near Limit · \(Int(pacingPercent * 100))% used"
            statusColorHex = "#FF9500" // Orange
        } else {
            statusText = "Over Budget"
            statusColorHex = "#FF3B30" // Red
        }
        
        // 4. Next upcoming subscription
        var nextSubTitle: String? = nil
        var nextSubAmount: Double? = nil
        var nextSubDays: Int? = nil
        
        let activeSubs = store.subscriptions.filter {
            !$0.isPaused && $0.status != "cancelled" && $0.nextBillingDate >= calendar.startOfDay(for: now)
        }.sorted(by: { $0.nextBillingDate < $1.nextBillingDate })
        
        if let firstSub = activeSubs.first {
            nextSubTitle = firstSub.name
            nextSubAmount = firstSub.amount
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: firstSub.nextBillingDate)).day ?? 0
            nextSubDays = max(0, days)
        }
        
        return BudgetPacingActivityAttributes.ContentState(
            spentToday: spentToday,
            dailyBudget: dailyBudget,
            remainingToday: remainingToday,
            pacingPercent: pacingPercent,
            statusText: statusText,
            statusColorHex: statusColorHex,
            nextSubscriptionTitle: nextSubTitle,
            nextSubscriptionAmount: nextSubAmount,
            nextSubscriptionDueDays: nextSubDays,
            lastUpdated: now
        )
    }
}
