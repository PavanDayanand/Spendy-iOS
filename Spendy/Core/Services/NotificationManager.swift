import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private var syncTask: Task<Void, Never>?
    private override init() { super.init() }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func refresh(from store: ExpenseStore) {
        let previous = syncTask
        previous?.cancel()
        let plans = SpendyNotificationPlan.build(transactions: store.transactions, subscriptions: store.subscriptions,
            currencyCode: store.currencyCode, bills: store.notificationsEnabled,
            weekly: store.weeklySummaryEnabled, logging: store.loggingRemindersEnabled)
        syncTask = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            let pending = await center.pendingNotificationRequests()
            guard !Task.isCancelled else { return }
            let ownedIDs = pending.map(\.identifier).filter {
                $0.hasPrefix("spendy.") || $0.hasPrefix("sub_reminder_") || $0.hasPrefix("budget_alert_")
            }
            center.removePendingNotificationRequests(withIdentifiers: ownedIDs)
            let status = await checkAuthorizationStatus()
            guard !Task.isCancelled, [.authorized, .provisional, .ephemeral].contains(status) else { return }
            for plan in plans {
                guard !Task.isCancelled else { return }
                let content = UNMutableNotificationContent()
                content.title = plan.title
                content.body = plan.body
                content.sound = .default
                content.threadIdentifier = plan.id.hasPrefix("spendy.bill") ? "spendy.bills" : "spendy.checkins"
                content.userInfo = ["url": plan.url]
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: plan.date)
                if let weekday = plan.repeatingWeekday { components = DateComponents(hour: 20, minute: 0, weekday: weekday) }
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: plan.repeatingWeekday != nil)
                do { try await center.add(UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger)) }
                catch { print("Could not schedule Spendy notification: \(error.localizedDescription)") }
            }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse) async {
        guard let rawURL = response.notification.request.content.userInfo["url"] as? String,
              let url = URL(string: rawURL) else { return }
        await MainActor.run { QuickActionManager.shared.handleURL(url) }
    }
}
