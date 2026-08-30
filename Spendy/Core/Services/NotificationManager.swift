//
//  NotificationManager.swift
//  Spendy
//
//  Local User Notifications for Upcoming Subscriptions and Budget Alerts
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Permission Request
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Subscription Billing Reminder
    func scheduleSubscriptionReminder(subscription: Subscription, daysInAdvance: Int = 1) {
        guard !subscription.isPaused else {
            cancelSubscriptionReminder(id: subscription.id)
            return
        }
        
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -daysInAdvance, to: subscription.nextBillingDate) ?? subscription.nextBillingDate
        
        // Ensure reminder is in the future
        guard targetDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Subscription: \(subscription.name)"
        content.body = "\(subscription.name) renewal of \(subscription.amount.formatted(.currency(code: "USD"))) is due on \(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "sub_reminder_\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule subscription notification: \(error)")
            }
        }
    }
    
    func cancelSubscriptionReminder(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["sub_reminder_\(id.uuidString)"])
    }
    
    // MARK: - Budget Threshold Alert
    func sendBudgetThresholdAlert(percentUsed: Double, budgetAmount: Double, currencySymbol: String) {
        let content = UNMutableNotificationContent()
        let pctInt = Int(percentUsed * 100)
        content.title = "Budget Alert: \(pctInt)% Reached"
        content.body = "You've used \(pctInt)% of your budget (\(currencySymbol)\(Int(budgetAmount))). Open Spendy to check your safe daily pace."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget_alert_\(pctInt)",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Sync All Active Subscriptions
    func syncAllSubscriptionReminders(subscriptions: [Subscription]) {
        for sub in subscriptions {
            scheduleSubscriptionReminder(subscription: sub)
        }
    }
}
